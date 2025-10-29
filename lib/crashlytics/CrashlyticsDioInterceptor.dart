import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';


typedef SampleFn = bool Function(RequestOptions rq, Response<dynamic>? rs, DioExceptionType type);

class CrashlyticsDioInterceptor extends Interceptor {
  CrashlyticsDioInterceptor({
    this.report4xx = true,
    this.report5xx = true,
    this.reportNetwork = true,
    this.sample, // optional: sampling function
    this.maxPreview = 800,
    this.includeReqHeaders = false, // avoid PII by default
  });

  final bool report4xx;
  final bool report5xx;
  final bool reportNetwork;
  final SampleFn? sample;
  final int maxPreview;
  final bool includeReqHeaders;

  String _safePreview(dynamic body) {
    try {
      final String s = body is String ? body : jsonEncode(body);
      return s.length > maxPreview ? '${s.substring(0, maxPreview)}…' : s;
    } catch (_) {
      final s = body?.toString() ?? '';
      return s.length > maxPreview ? '${s.substring(0, maxPreview)}…' : s;
    }
  }

  bool _shouldReport(Response? response, DioExceptionType type) {
    if (type != DioExceptionType.badResponse) return reportNetwork;
    final code = response?.statusCode ?? 0;
    if (code >= 500) return report5xx;
    if (code >= 400) return report4xx;
    return false;
  }

  Future<void> _record({
    required DioException err,
    Map<String, Object?> extra = const {},
  }) async {
    final rq = err.requestOptions;
    final rs = err.response;

    // Allow call-site opt-out
    if (rq.extra['skipCrashlytics'] == true) return;

    // Optional sampling
    if (sample != null && !sample!(rq, rs, err.type)) return;

    await FirebaseCrashlytics.instance.setCustomKey('api_method', rq.method);
    await FirebaseCrashlytics.instance.setCustomKey('api_url', rq.uri.toString());
    await FirebaseCrashlytics.instance.setCustomKey('api_status', rs?.statusCode ?? -1);
    await FirebaseCrashlytics.instance.setCustomKey('api_type', err.type.name);
    if (rq.extra['feature'] != null) {
      await FirebaseCrashlytics.instance.setCustomKey('feature', rq.extra['feature'].toString());
    }

    final info = <DiagnosticsNode>[
      DiagnosticsNode.message('query: ${rq.queryParameters}'),
      if (includeReqHeaders) DiagnosticsNode.message('reqHeaders: ${rq.headers}'),
      if (rq.data != null) DiagnosticsNode.message('reqBody: ${_safePreview(rq.data)}'),
      if (rs != null) DiagnosticsNode.message('resData: ${_safePreview(rs.data)}'),
    ];

    await FirebaseCrashlytics.instance.recordError(
      err,
      err.stackTrace ?? StackTrace.current,
      fatal: false,
      information: info,
      reason: 'Dio ${rq.method} ${rq.uri} failed',
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      if (_shouldReport(err.response, err.type)) {
        await _record(err: err);
      }
    } catch (_) {/* no-op */}
    return handler.next(err);
  }

  /// If validateStatus returns true, Dio won’t throw on 4xx/5xx.
  /// We still want to report those as non-fatals.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final code = response.statusCode ?? 0;
      if (code >= 400 && _shouldReport(response, DioExceptionType.badResponse)) {
        final err = DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'HTTP $code ${response.requestOptions.uri}',
        );
        await _record(err: err);
      }
    } catch (_) {/* no-op */}
    return handler.next(response);
  }
}
