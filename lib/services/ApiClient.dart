import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mentivisor/utils/AppLogger.dart';
import '../core/network/api_config.dart';
import '../core/network/mentee_endpoints.dart';
import '../utils/CrashlyticsDioInterceptor.dart';
import '../utils/constants.dart';
import 'AuthService.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      // We accept all statuses so responses reach onResponse; we’ll log 4xx/5xx ourselves.
      validateStatus: (_) => true,
    ),
  );

  static const List<String> _unauthenticatedEndpoints = [
    '/api/user-login',
    '/api/registration-step-1',
    '/api/registration-verify-step-2',
    '/api/final-registration',
    '/api/campuses',
    '/api/years',
    '/api/banners',
    '/api/study-zone/tags',
    '/api/study-zone/top-downloads',
    '/api/guest-list-ecc',
    '/api/community-zone-post-without-login',
    '/api/top-mentors',
    '/api/tags',
    '/api/forget-password',
    '/api/verify-otp',
    '/api/reset-password',
    '/api/upload-file',
  ];

  static void setupInterceptors() {
    try {
      _dio.interceptors.clear();

      // 1) Console logging in debug
      _dio.interceptors.add(
        LogInterceptor(
          request: kDebugMode,
          requestHeader: kDebugMode,
          requestBody: kDebugMode,
          responseHeader: kDebugMode,
          responseBody: kDebugMode,
          error: true,
        ),
      );

      // 2) Crashlytics
      _dio.interceptors.add(CrashlyticsDioInterceptor());

      // 3) Auth & navigation wrapper
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final isUnauthenticated = _unauthenticatedEndpoints.any(
                  (endpoint) => options.uri.path.startsWith(endpoint),
            );

            // Attach feature name optionally: options.extra['feature'] = 'profile_update';
            // Allow opt-out per call: options.extra['skipCrashlytics'] = true;

            if (isUnauthenticated) {
              return handler.next(options);
            }

            final accessToken = await AuthService.getAccessToken();
            AppLogger.info("accesstoken: $accessToken");

            if (accessToken == null || accessToken.isEmpty) {
              await AuthService.logout();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'No access token, please log in again',
                  type: DioExceptionType.cancel,
                ),
              );
            } else {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }

            return handler.next(options);
          },

          onResponse: (response, handler) async {
            // Backend-driven token expiry (business status)
            if (response.data is Map<String, dynamic>) {
              final data = response.data as Map<String, dynamic>;
              if (data['status'] == false && data['message'] == 'Token is expired') {
                await AuthService.logout();
                return handler.reject(
                  DioException(
                    requestOptions: response.requestOptions,
                    error: 'Token expired',
                    response: response,
                    type: DioExceptionType.badResponse,
                  ),
                );
              }
            }

            // Optional: central navigation on certain status codes
            _handleNavigation(response.statusCode, navigatorKey);

            return handler.next(response);
          },

          onError: (DioException e, handler) async {
            final isUnauthenticated = _unauthenticatedEndpoints.any(
                  (endpoint) => e.requestOptions.uri.path.startsWith(endpoint),
            );

            if (!isUnauthenticated && e.response?.statusCode == 401) {
              await AuthService.logout();
              // Let the UI catch this rejection and route to login
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: 'Unauthorized, please log in again',
                  type: DioExceptionType.badResponse,
                  response: e.response,
                ),
              );
            }

            return handler.next(e);
          },
        ),
      );
    } catch (e, stackTrace) {
      // Record unexpected setup failures
      FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
    }
  }

  // --- HTTP verbs (unchanged except passing options through) ---

  static Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      AppLogger.log("called get method");
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> post(String path, {dynamic data, Options? options}) async {
    try {
      return await _dio.post(path, data: data, options: options);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> put(
      String path, {
        dynamic data,
        Options? options,
      }) async {
    try {
      return await _dio.put(path, data: data, options: options);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Future<Response> delete(String path, {Options? options}) async {
    try {
      return await _dio.delete(path, options: options);
    } catch (e) {
      return _handleError(e);
    }
  }

  static Never _handleError(dynamic error) {
    if (error is DioException) {
      throw error; // already captured by interceptor
    } else {
      final ex = Exception("Unexpected error occurred");
      FirebaseCrashlytics.instance.recordError(error, StackTrace.current, fatal: false);
      throw ex;
    }
  }


  static void _handleNavigation(
      int? statusCode,
      GlobalKey<NavigatorState> navigatorKey,
      ) {
    // Example: if (statusCode == 403) navigatorKey.currentState?.pushNamed('/no-access');
  }
}

