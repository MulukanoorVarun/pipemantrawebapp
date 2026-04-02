import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  String savePath;
  DownloadStatus status;
  double progress;
  int receivedBytes;
  int totalBytes;
  String? errorMessage;
  final CancelToken cancelToken;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    this.savePath = '',
    this.status = DownloadStatus.pending,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    CancelToken? cancelToken,
  }) : cancelToken = cancelToken ?? CancelToken();

  String get formattedSize {
    if (totalBytes == 0) return '';
    if (totalBytes < 1024) return '${totalBytes}B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedReceived {
    if (receivedBytes < 1024) return '${receivedBytes}B';
    if (receivedBytes < 1024 * 1024) {
      return '${(receivedBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

void _log(String message) {
  if (kDebugMode) debugPrint('[DownloadManager] $message');
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadTask> _tasks = [];
  final Dio _dio = Dio();

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  bool get hasActive => _tasks.any(
    (t) =>
        t.status == DownloadStatus.downloading ||
        t.status == DownloadStatus.pending,
  );

  /// Entry point — called from WebView's onDownloadStartRequest.
  /// [webViewController] is needed to handle blob: URLs via JavaScript.
  Future<void> enqueue(
    BuildContext context,
    String url,
    String filename,
    InAppWebViewController? webViewController,
  ) async {
    _log('Download requested: url=$url, filename=$filename');

    // Validate URL
    if (url.isEmpty) {
      _log('ERROR: Empty URL');
      _showSnack(context, 'Download failed: invalid URL', isError: true);
      return;
    }

    // Deduplicate
    if (_tasks.any(
      (t) =>
          t.url == url &&
          (t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending),
    )) {
      _log('Skipped: already downloading $filename');
      _showSnack(context, 'Already downloading $filename');
      return;
    }

    // Permissions
    _log('Checking permissions...');
    final permitted = await _requestPermissions(context);
    _log('Permission result: $permitted');
    if (!permitted) return;

    // Build save path
    final savePath = await _buildSavePath(filename);
    _log('Save path: $savePath');

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      filename: filename,
      savePath: savePath,
    );

    _tasks.insert(0, task);
    notifyListeners();

    if (url.startsWith('blob:')) {
      _log('Detected blob URL — using JS bridge download');
      await _downloadBlob(context, task, webViewController);
    } else {
      _log('Detected HTTP URL — using Dio download');
      await _downloadHttp(context, task);
    }
  }

  // ── Blob download (PDF from blob: URLs) ─────────────────────
  //
  // blob: URLs are in-memory browser objects. Dio/HTTP clients cannot
  // access them. We must use JavaScript inside the WebView to:
  //   1. fetch() the blob
  //   2. Read it as a base64 data-URL via FileReader
  //   3. Return the base64 string to Dart
  //   4. Decode and write to disk
  //
  // CRITICAL: evaluateJavascript() does NOT await JS Promises — it
  // returns null for async functions. We MUST use callAsyncJavaScript()
  // which properly resolves the Promise before returning.
  Future<void> _downloadBlob(
    BuildContext context,
    DownloadTask task,
    InAppWebViewController? controller,
  ) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    if (controller == null) {
      _log('ERROR: WebView controller is null');
      _failTask(context, task, 'WebView not available');
      return;
    }

    try {
      _log('Step 1: Executing JS to fetch blob and convert to base64...');

      // callAsyncJavaScript properly awaits the Promise returned by the
      // async function — unlike evaluateJavascript which returns null.
      final callResult = await controller.callAsyncJavaScript(
        functionBody: """
    try {
      const blobUrl = arguments.blobUrl; // ✅ FIX: define it

      var response = await fetch(blobUrl);
      if (!response.ok) {
        return { error: 'Fetch failed: HTTP ' + response.status };
      }

      var blob = await response.blob();

      var base64 = await new Promise(function(resolve, reject) {
        var reader = new FileReader();
        reader.onloadend = function() { resolve(reader.result); };
        reader.onerror = function() { reject('FileReader error'); };
        reader.readAsDataURL(blob);
      });

      return { data: base64, size: blob.size, type: blob.type };
    } catch(e) {
      return { error: e.toString() };
    }
  """,
        arguments: {'blobUrl': task.url},
      );

      _log('Step 2: JS execution completed. Parsing result...');

      // callAsyncJavaScript returns a CallAsyncJavaScriptResult
      final value = callResult?.value;
      final error = callResult?.error;

      if (error != null) {
        _log('ERROR: JS execution error: $error');
        _failTask(context, task, 'Could not read file: $error');
        return;
      }

      if (value == null) {
        _log('ERROR: JS returned null');
        _failTask(context, task, 'Could not read file data');
        return;
      }

      // value is a Map from the JS object we returned
      if (value is Map) {
        if (value.containsKey('error')) {
          _log('ERROR: JS fetch error: ${value['error']}');
          _failTask(context, task, 'File read error: ${value['error']}');
          return;
        }

        final dataUrl = value['data']?.toString();
        final blobSize = value['size'];
        final blobType = value['type'];

        _log('Step 3: Got data URL. Blob type=$blobType, size=$blobSize');

        if (dataUrl == null || !dataUrl.contains(',')) {
          _log('ERROR: Invalid data URL format');
          _failTask(context, task, 'Invalid file data received');
          return;
        }

        // Extract base64 from "data:application/pdf;base64,JVBERi0..."
        final base64Str = dataUrl.substring(dataUrl.indexOf(',') + 1);

        _log('Step 4: Decoding base64 (${base64Str.length} chars)...');
        final bytes = base64Decode(base64Str);
        _log(
          'Step 5: Decoded ${bytes.length} bytes. Writing to ${task.savePath}...',
        );

        final file = File(task.savePath);
        await file.writeAsBytes(bytes, flush: true);

        // Verify file was written
        final exists = await file.exists();
        final fileSize = exists ? await file.length() : 0;
        _log('Step 6: File written. exists=$exists, size=$fileSize');

        if (!exists || fileSize == 0) {
          _failTask(context, task, 'File save failed — disk may be full');
          return;
        }

        task.receivedBytes = bytes.length;
        task.totalBytes = bytes.length;
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
        notifyListeners();

        _log('SUCCESS: ${task.filename} downloaded (${task.formattedSize})');
        if (context.mounted) {
          _showCompletedSnack(context, task);
        }
      } else {
        // Unexpected return type
        _log('ERROR: Unexpected JS result type: ${value.runtimeType} → $value');
        _failTask(context, task, 'Unexpected response from browser');
      }
    } catch (e, stack) {
      _log('EXCEPTION in _downloadBlob: $e\n$stack');
      _failTask(context, task, 'Download error: ${e.toString()}');
    }
  }

  // ── HTTP download (normal URLs) ─────────────────────────────
  Future<void> _downloadHttp(BuildContext context, DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    try {
      _log('HTTP download starting: ${task.url}');
      await _dio.download(
        task.url,
        task.savePath,
        cancelToken: task.cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          task.receivedBytes = received;
          task.totalBytes = total == -1 ? 0 : total;
          task.progress = total > 0 ? received / total : 0;
          notifyListeners();
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          headers: {'Accept': '*/*'},
        ),
      );

      // Verify
      final file = File(task.savePath);
      final exists = await file.exists();
      _log('HTTP download done. File exists=$exists, path=${task.savePath}');

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      notifyListeners();

      if (context.mounted) {
        _showCompletedSnack(context, task);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _log('Download cancelled by user');
        task.status = DownloadStatus.cancelled;
      } else {
        final msg = _friendlyError(e);
        _log('HTTP download error: ${e.type} — $msg');
        task.status = DownloadStatus.failed;
        task.errorMessage = msg;
        if (context.mounted) {
          _showSnack(context, msg, isError: true);
        }
      }
      notifyListeners();
    } catch (e) {
      _log('HTTP download exception: $e');
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _failTask(BuildContext context, DownloadTask task, String message) {
    _log('FAIL: ${task.filename} — $message');
    task.status = DownloadStatus.failed;
    task.errorMessage = message;
    notifyListeners();
    if (context.mounted) {
      _showSnack(context, message, isError: true);
    }
  }

  void cancel(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx].cancelToken.cancel();
    _tasks[idx].status = DownloadStatus.cancelled;
    notifyListeners();
  }

  void retry(BuildContext context, String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.pending;
    task.progress = 0;
    task.receivedBytes = 0;
    task.errorMessage = null;
    notifyListeners();
    _downloadHttp(context, task);
  }

  void remove(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  Future<void> openFile(DownloadTask task) async {
    if (task.status != DownloadStatus.completed) return;
    final file = File(task.savePath);
    if (!await file.exists()) {
      _log('openFile: File not found at ${task.savePath}');
      return;
    }
    await OpenFilex.open(task.savePath);
  }

  // ── Permission handling ──────────────────────────────────────
  Future<bool> _requestPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Android 10+ (API 29): scoped storage — apps can write to the shared
    // Downloads directory without WRITE_EXTERNAL_STORAGE.
    //
    // Android 13+ (API 33): Permission.storage no longer exists in the
    // manifest. Requesting it causes "No permissions found in manifest"
    // and always returns denied. We must skip it entirely.
    //
    // Strategy: Try writing a test file to Downloads. If it works,
    // no permission needed (API 29+). Only fall back to Permission.storage
    // for very old devices (API < 29).
    try {
      final testDir = Directory('/storage/emulated/0/Download');
      if (await testDir.exists()) {
        final testFile = File(
          '${testDir.path}/.pipemantra_perm_test_${DateTime.now().millisecondsSinceEpoch}',
        );
        await testFile.writeAsString('test');
        await testFile.delete();
        _log('Downloads directory is writable — no permission needed');
        return true;
      }
    } catch (e) {
      _log('Downloads write test failed: $e — trying Permission.storage');
    }

    // Fallback for API < 29
    try {
      final status = await Permission.storage.request();
      _log('Permission.storage result: $status');
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        if (context.mounted) _showPermissionDialog(context);
        return false;
      }
    } catch (e) {
      _log('Permission.storage request threw: $e — assuming not needed');
    }

    // Last resort: use app-private directory (always writable, no permission)
    _log('Falling back to app-private directory');
    return true;
  }

  Future<String> _buildSavePath(String filename) async {
    Directory dir;
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      bool canUseDownloads = false;

      if (await downloadsDir.exists()) {
        // Verify we can actually write there
        try {
          final testFile = File(
            '${downloadsDir.path}/.pipemantra_write_test_${DateTime.now().millisecondsSinceEpoch}',
          );
          await testFile.writeAsString('test');
          await testFile.delete();
          canUseDownloads = true;
        } catch (_) {
          canUseDownloads = false;
        }
      }

      if (canUseDownloads) {
        dir = downloadsDir;
      } else {
        // Fallback chain: external storage → app documents
        dir =
            (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    _log('Using directory: ${dir.path}');

    String finalName = filename;
    String base = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    String ext = filename.contains('.') ? '.${filename.split('.').last}' : '';
    int counter = 1;
    while (await File('${dir.path}/$finalName').exists()) {
      finalName = '$base($counter)$ext';
      counter++;
    }

    return '${dir.path}/$finalName';
  }

  String _friendlyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode})';
      default:
        return 'Download failed. Please try again.';
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFB71C1C)
            : const Color(0xFF1A237E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCompletedSnack(BuildContext context, DownloadTask task) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Downloaded: ${task.filename}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: const Color(0xFF90CAF9),
          onPressed: () => openFile(task),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Storage Permission Required'),
        content: const Text(
          'Pipemantra needs storage access to save files to your device. '
          'Please grant permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001f3f),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
