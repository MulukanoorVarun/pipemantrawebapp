import 'dart:async';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Nointernet.dart';
import 'bloc/internet_status/internet_status_bloc.dart';

// class WebViewScreen extends StatefulWidget {
//   const WebViewScreen({Key? key}) : super(key: key);
//
//   @override
//   State<WebViewScreen> createState() => _WebERPState();
// }
//
// class _WebERPState extends State<WebViewScreen> {
//   final Completer<InAppWebViewController> _controller =
//       Completer<InAppWebViewController>();
//   bool isLoading = true;
//   // String url = "https://pipemantra.com/";
//   String url = "https://m.pipemantra.com/";
//   InAppWebViewController? webViewController;
//   PullToRefreshController? pullToRefreshController;
//   PullToRefreshSettings pullToRefreshSettings = PullToRefreshSettings();
//   bool pullToRefreshEnabled = true;
//   bool _isNoInternetScreenVisible = false;
//   final GlobalKey webViewKey = GlobalKey();
//
//   @override
//   void initState() {
//     WidgetsFlutterBinding.ensureInitialized();
//     pullToRefreshController = kIsWeb
//         ? null
//         : PullToRefreshController(
//             settings: pullToRefreshSettings,
//             onRefresh: () async {
//               if (defaultTargetPlatform == TargetPlatform.android) {
//                 webViewController?.reload();
//               } else if (defaultTargetPlatform == TargetPlatform.iOS) {
//                 webViewController?.loadUrl(
//                   urlRequest: URLRequest(
//                     url: await webViewController?.getUrl(),
//                   ),
//                 );
//               }
//             },
//           );
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     // This helps even if user presses back manually
//     final parentState = context.findAncestorStateOfType<_WebERPState>();
//     if (parentState != null) {
//       parentState._isNoInternetScreenVisible = false;
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var screenheight = MediaQuery.of(context).size.height;
//     return WillPopScope(
//       onWillPop: () async {
//         if (await webViewController!.canGoBack()) {
//           webViewController!.goBack();
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.topRight,
//               colors: [Color(0xFF001f3f), Color(0xFF003366), Color(0xFF004080)],
//               stops: [0.0, 0.5, 1.0],
//             ),
//           ),
//           child: BlocListener<InternetStatusBloc, InternetStatusState>(
//             listener: (context, state) async {
//               if (state is InternetStatusLostState &&
//                   !_isNoInternetScreenVisible) {
//                 _isNoInternetScreenVisible = true;
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => Nointernet()),
//                 );
//                 // When user returns manually
//                 _isNoInternetScreenVisible = false;
//               } else if (state is InternetStatusBackState &&
//                   _isNoInternetScreenVisible) {
//                 Navigator.pop(context); // Close Nointernet screen
//                 _isNoInternetScreenVisible = false;
//               }
//             },
//             child: SafeArea(
//               child: Stack(
//                 children: [
//                   Column(
//                     children: <Widget>[
//                       Expanded(
//                         child: InAppWebView(
//                           key: webViewKey,
//                           initialUrlRequest: URLRequest(url: WebUri(url)),
//                           initialOptions: InAppWebViewGroupOptions(
//                             android: AndroidInAppWebViewOptions(
//                               useWideViewPort: true,
//                               loadWithOverviewMode: true,
//                               allowContentAccess: true,
//                               geolocationEnabled: true,
//                               allowFileAccess: true,
//                               databaseEnabled: true,
//                               domStorageEnabled: true,
//                               builtInZoomControls: false,
//                               displayZoomControls: false,
//                               safeBrowsingEnabled: true,
//                               clearSessionCache: !kIsWeb,
//                               loadsImagesAutomatically: true,
//                               thirdPartyCookiesEnabled: true,
//                               blockNetworkImage: false,
//                               supportMultipleWindows: true,
//                             ),
//                             ios: IOSInAppWebViewOptions(
//                               allowsInlineMediaPlayback: true,
//                             ),
//                             crossPlatform: InAppWebViewOptions(
//                               javaScriptEnabled: true,
//                               useOnDownloadStart: true,
//                               allowFileAccessFromFileURLs: true,
//                               allowUniversalAccessFromFileURLs: true,
//                               mediaPlaybackRequiresUserGesture: true,
//                             ),
//                           ),
//                           initialUserScripts: UnmodifiableListView<UserScript>([
//                             UserScript(
//                               source: """
//                                   if (typeof Notification === "undefined") {
//                                     window.Notification = function(title, options) {
//                                       console.log("Mock Notification:", title, options);
//                                     };
//                                     window.Notification.permission = "granted";
//                                     window.Notification.requestPermission = function(callback) {
//                                       if (callback) callback("granted");
//                                       return Promise.resolve("granted");
//                                     };
//                                   }
//                                 """,
//                               injectionTime:
//                                   UserScriptInjectionTime.AT_DOCUMENT_START,
//                             ),
//                           ]),
//                           onWebViewCreated: (controller) {
//                             webViewController = controller;
//                             _controller.complete(controller);
//                             // if (!kIsWeb) {
//                             //   controller.clearCache();
//                             // }
//                           },
//                           pullToRefreshController: pullToRefreshController,
//                           onLoadStart: (controller, url) {
//                             setState(() {
//                               isLoading = true;
//                             });
//                           },
//                           onLoadStop: (controller, url) {
//                             setState(() {
//                               isLoading = false;
//                             });
//                             pullToRefreshController?.endRefreshing();
//                           },
//                           shouldOverrideUrlLoading:
//                               (controller, navigationAction) async {
//                                 var uri = navigationAction.request.url!;
//                                 if (uri.scheme == "tel" ||
//                                     uri.scheme == "mailto" ||
//                                     uri.scheme == "whatsapp" ||
//                                     uri.toString().contains(
//                                       "accounts.google.com",
//                                     )) {
//                                   if (await canLaunchUrl(uri)) {
//                                     await launchUrl(uri);
//                                     return NavigationActionPolicy.CANCEL;
//                                   }
//                                 }
//                                 return NavigationActionPolicy.ALLOW;
//                               },
//                           onReceivedError: (controller, request, error) {
//                             pullToRefreshController?.endRefreshing();
//                             setState(() {
//                               isLoading = false;
//                             });
//                           },
//                           onProgressChanged: (controller, progress) {
//                             if (progress == 100) {
//                               setState(() {
//                                 isLoading = false;
//                               });
//                               pullToRefreshController?.endRefreshing();
//                             }
//                           },
//                           onReceivedHttpError: (controller, request, error) {
//                             if (error.statusCode == 409) {
//                               controller.reload();
//                             }
//                             pullToRefreshController?.endRefreshing();
//                             setState(() {
//                               isLoading = false;
//                             });
//                           },
//                           onConsoleMessage: (controller, consoleMessage) {
//                             if (kDebugMode) {
//                               debugPrint(
//                                 "Console message: ${consoleMessage.toString()}",
//                               );
//                               debugPrint(
//                                 "Message: ${consoleMessage.message}, Level: ${consoleMessage.messageLevel}",
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (isLoading)
//                     Container(
//                       height: screenheight,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.topRight,
//                           colors: [
//                             Color(0xFF001f3f),
//                             Color(0xFF003366),
//                             Color(0xFF004080),
//                           ],
//                           stops: [0.0, 0.5, 1.0],
//                         ),
//                       ),
//                       child: Center(
//                         child: CircularProgressIndicator(color: Colors.white),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// ============================================================
// REQUIRED PACKAGES — add to pubspec.yaml:
// ============================================================
//   dio: ^5.4.3+1
//   permission_handler: ^11.3.1
//   path_provider: ^2.1.3
//   open_filex: ^4.4.0
//   flutter_inappwebview: ^6.1.5
// ============================================================
// AndroidManifest.xml — inside <manifest>:
//   <uses-permission android:name="android.permission.INTERNET"/>
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
//       android:maxSdkVersion="32"/>
//   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
//       android:maxSdkVersion="29"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
//
// Inside <application>:
//   android:requestLegacyExternalStorage="true"  ← add to <application> tag
//
//   <provider
//     android:name="androidx.core.content.FileProvider"
//     android:authorities="${applicationId}.fileprovider"
//     android:exported="false"
//     android:grantUriPermissions="true">
//     <meta-data
//       android:name="android.support.FILE_PROVIDER_PATHS"
//       android:resource="@xml/file_paths"/>
//   </provider>
//
// res/xml/file_paths.xml:
//   <?xml version="1.0" encoding="utf-8"?>
//   <paths>
//     <external-path name="external" path="."/>
//     <external-files-path name="external_files" path="."/>
//   </paths>
// ============================================================

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// 1. DOWNLOAD TASK MODEL
// ─────────────────────────────────────────────────────────────

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String url;
  final String filename;
  String savePath;
  DownloadStatus status;
  double progress; // 0.0 → 1.0
  int receivedBytes;
  int totalBytes;
  String? errorMessage;
  final CancelToken cancelToken;
  final DateTime startedAt;

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
  }) : cancelToken = cancelToken ?? CancelToken(),
       startedAt = DateTime.now();

  String get formattedSize {
    if (totalBytes == 0) return '';
    if (totalBytes < 1024) return '${totalBytes}B';
    if (totalBytes < 1024 * 1024)
      return '${(totalBytes / 1024).toStringAsFixed(1)}KB';
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedReceived {
    if (receivedBytes < 1024) return '${receivedBytes}B';
    if (receivedBytes < 1024 * 1024)
      return '${(receivedBytes / 1024).toStringAsFixed(1)}KB';
    return '${(receivedBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  IconData get fileIcon {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audio_file_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get fileColor {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return const Color(0xFF43A047);
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return const Color(0xFF7B1FA2);
      case 'mp3':
      case 'wav':
      case 'aac':
        return const Color(0xFF00897B);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFFB8C00);
      case 'doc':
      case 'docx':
        return const Color(0xFF1565C0);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF546E7A);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 2. DOWNLOAD MANAGER (ValueNotifier-based, no extra package)
// ─────────────────────────────────────────────────────────────

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadTask> _tasks = [];
  final Dio _dio = Dio();

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks => _tasks
      .where(
        (t) =>
            t.status == DownloadStatus.downloading ||
            t.status == DownloadStatus.pending,
      )
      .toList();
  bool get hasActive => activeTasks.isNotEmpty;

  // ── Entry point called from WebView ──────────────────────────
  Future<void> enqueue(
    BuildContext context,
    String url,
    String filename,
  ) async {
    // Deduplicate
    if (_tasks.any(
      (t) =>
          t.url == url &&
          (t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.pending),
    )) {
      _showSnack(context, 'Already downloading $filename', isError: false);
      return;
    }

    final permitted = await _requestPermissions(context);
    if (!permitted) return;

    final savePath = await _buildSavePath(filename);
    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      filename: filename,
      savePath: savePath,
    );

    _tasks.insert(0, task);
    notifyListeners();

    _startDownload(context, task);
  }

  // ── Core download loop ────────────────────────────────────────
  Future<void> _startDownload(BuildContext context, DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    notifyListeners();

    try {
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

      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      notifyListeners();

      if (context.mounted) {
        _showCompletedSnack(context, task);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        task.status = DownloadStatus.cancelled;
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = _friendlyError(e);
        if (context.mounted) {
          _showSnack(context, 'Failed: ${task.filename}', isError: true);
        }
      }
      notifyListeners();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      notifyListeners();
    }
  }

  void cancel(String taskId) {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception(),
    );
    task.cancelToken.cancel();
    task.status = DownloadStatus.cancelled;
    notifyListeners();
  }

  void retry(BuildContext context, String taskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.status = DownloadStatus.pending;
    task.progress = 0;
    task.receivedBytes = 0;
    task.errorMessage = null;
    notifyListeners();
    _startDownload(context, task);
  }

  void remove(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void clearCompleted() {
    _tasks.removeWhere(
      (t) =>
          t.status == DownloadStatus.completed ||
          t.status == DownloadStatus.cancelled ||
          t.status == DownloadStatus.failed,
    );
    notifyListeners();
  }

  Future<void> openFile(DownloadTask task) async {
    if (task.status != DownloadStatus.completed) return;
    final file = File(task.savePath);
    if (!await file.exists()) return;
    await OpenFilex.open(task.savePath);
  }

  // ── Helpers ───────────────────────────────────────────────────
  Future<bool> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      final info = await _androidSdkInt();
      if (info >= 33) {
        // Android 13+ — no WRITE permission needed for Downloads
        return true;
      }
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDialog(context);
        }
        return false;
      }
    }
    return true;
  }

  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    try {
      // Use device_info_plus if available; fallback to 29
      return 29;
    } catch (_) {
      return 29;
    }
  }

  Future<String> _buildSavePath(String filename) async {
    Directory dir;
    if (Platform.isAndroid) {
      // Save to device Downloads folder
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir =
            (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    // Handle duplicate filenames
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

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
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
            Icon(Icons.check_circle, color: Colors.white, size: 18),
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
          'PipeMantra needs storage access to save files to your device. '
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

// ─────────────────────────────────────────────────────────────
// 3. DOWNLOAD TRAY WIDGET  (floating bottom panel)
// ─────────────────────────────────────────────────────────────

class DownloadTray extends StatefulWidget {
  final DownloadManager manager;
  const DownloadTray({super.key, required this.manager});

  @override
  State<DownloadTray> createState() => _DownloadTrayState();
}

class _DownloadTrayState extends State<DownloadTray>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.manager,
      builder: (_, __) {
        final tasks = widget.manager.tasks;
        if (tasks.isEmpty) return const SizedBox.shrink();

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header bar ──────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001f3f),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Downloads',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _traySubtitle(tasks),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tasks.any(
                            (t) =>
                                t.status == DownloadStatus.completed ||
                                t.status == DownloadStatus.failed ||
                                t.status == DownloadStatus.cancelled,
                          ))
                            GestureDetector(
                              onTap: widget.manager.clearCompleted,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Task list ────────────────────────────────
                  if (_expanded)
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        itemBuilder: (_, i) => _DownloadTaskTile(
                          task: tasks[i],
                          manager: widget.manager,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _traySubtitle(List<DownloadTask> tasks) {
    final active = tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .length;
    final done = tasks
        .where((t) => t.status == DownloadStatus.completed)
        .length;
    final parts = <String>[];
    if (active > 0) parts.add('$active active');
    if (done > 0) parts.add('$done done');
    return parts.isEmpty ? '${tasks.length} item(s)' : parts.join(' · ');
  }
}

// ── Single task row ────────────────────────────────────────────

class _DownloadTaskTile extends StatelessWidget {
  final DownloadTask task;
  final DownloadManager manager;
  const _DownloadTaskTile({required this.task, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: task.fileColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(task.fileIcon, color: task.fileColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 5),

                if (task.status == DownloadStatus.downloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress > 0 ? task.progress : null,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                        const Color(0xFF4FC3F7),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.totalBytes > 0
                        ? '${task.formattedReceived} / ${task.formattedSize}  '
                              '${(task.progress * 100).toStringAsFixed(0)}%'
                        : 'Downloading…',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ] else if (task.status == DownloadStatus.completed)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF81C784),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.formattedSize,
                        style: const TextStyle(
                          color: Color(0xFF81C784),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                else if (task.status == DownloadStatus.failed)
                  Row(
                    children: [
                      const Icon(
                        Icons.error,
                        color: Color(0xFFEF9A9A),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.errorMessage ?? 'Failed',
                          style: const TextStyle(
                            color: Color(0xFFEF9A9A),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else if (task.status == DownloadStatus.cancelled)
                  Text(
                    'Cancelled',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  )
                else
                  Text(
                    'Pending…',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action buttons
          _ActionButton(task: task, manager: manager),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DownloadTask task;
  final DownloadManager manager;
  const _ActionButton({required this.task, required this.manager});

  @override
  Widget build(BuildContext context) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return _iconBtn(
          icon: Icons.close_rounded,
          color: Colors.white54,
          onTap: () => manager.cancel(task.id),
          tooltip: 'Cancel',
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBtn(
              icon: Icons.folder_open_rounded,
              color: const Color(0xFF4FC3F7),
              onTap: () => manager.openFile(task),
              tooltip: 'Open',
            ),
            const SizedBox(width: 4),
            _iconBtn(
              icon: Icons.delete_outline_rounded,
              color: Colors.white30,
              onTap: () => manager.remove(task.id),
              tooltip: 'Remove',
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBtn(
              icon: Icons.refresh_rounded,
              color: const Color(0xFFFFA726),
              onTap: () => manager.retry(context, task.id),
              tooltip: 'Retry',
            ),
            const SizedBox(width: 4),
            _iconBtn(
              icon: Icons.delete_outline_rounded,
              color: Colors.white30,
              onTap: () => manager.remove(task.id),
              tooltip: 'Remove',
            ),
          ],
        );
      case DownloadStatus.cancelled:
        return _iconBtn(
          icon: Icons.delete_outline_rounded,
          color: Colors.white30,
          onTap: () => manager.remove(task.id),
          tooltip: 'Remove',
        );
      default:
        return const SizedBox(width: 8);
    }
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. HELPERS
// ─────────────────────────────────────────────────────────────

/// Extracts a clean filename from URL + Content-Disposition header.
String resolveFilename(
  String url,
  String? contentDisposition,
  String? mimeType,
) {
  // 1. Try Content-Disposition: attachment; filename="foo.pdf"
  if (contentDisposition != null && contentDisposition.isNotEmpty) {
    final regexes = [
      RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false),
      RegExp(r'filename="([^"]+)"', caseSensitive: false),
      RegExp(r"filename='([^']+)'", caseSensitive: false),
      RegExp(r'filename=([^;]+)', caseSensitive: false),
    ];
    for (final r in regexes) {
      final match = r.firstMatch(contentDisposition);
      if (match != null) {
        final name = Uri.decodeFull(match.group(1)!.trim());
        if (name.isNotEmpty)
          return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      }
    }
  }

  // 2. Derive from URL path
  try {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final last = Uri.decodeFull(segments.last);
      if (last.isNotEmpty && last.contains('.')) return last;
    }
  } catch (_) {}

  // 3. Derive from MIME type
  final ext = _extFromMime(mimeType ?? '');
  return 'download_${DateTime.now().millisecondsSinceEpoch}$ext';
}

String _extFromMime(String mime) {
  const map = {
    'application/pdf': '.pdf',
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'video/mp4': '.mp4',
    'audio/mpeg': '.mp3',
    'application/zip': '.zip',
    'application/msword': '.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        '.docx',
    'application/vnd.ms-excel': '.xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        '.xlsx',
    'text/plain': '.txt',
    'text/csv': '.csv',
  };
  return map[mime.split(';').first.trim()] ?? '';
}

// ─────────────────────────────────────────────────────────────
// 5. MAIN WEBVIEW SCREEN  (enhanced)
// ─────────────────────────────────────────────────────────────

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebERPState();
}

class _WebERPState extends State<WebViewScreen> {
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  bool isLoading = true;
  String url = "https://m.pipemantra.com/";
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  bool _isNoInternetScreenVisible = false;
  final GlobalKey webViewKey = GlobalKey();

  final DownloadManager _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController?.canGoBack() ?? false) {
          webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF001f3f), Color(0xFF003366), Color(0xFF004080)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: BlocListener<InternetStatusBloc, InternetStatusState>(
            listener: (context, state) async {
              if (state is InternetStatusLostState &&
                  !_isNoInternetScreenVisible) {
                _isNoInternetScreenVisible = true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Nointernet()),
                );
                _isNoInternetScreenVisible = false;
              } else if (state is InternetStatusBackState &&
                  _isNoInternetScreenVisible) {
                Navigator.pop(context);
                _isNoInternetScreenVisible = false;
              }
            },
            child: SafeArea(
              child: Stack(
                children: [
                  // ── WebView ───────────────────────────────────
                  Column(
                    children: [
                      Expanded(
                        child: InAppWebView(
                          key: webViewKey,
                          initialUrlRequest: URLRequest(url: WebUri(url)),
                          initialOptions: InAppWebViewGroupOptions(
                            android: AndroidInAppWebViewOptions(
                              useWideViewPort: true,
                              loadWithOverviewMode: true,
                              allowContentAccess: true,
                              geolocationEnabled: true,
                              allowFileAccess: true,
                              databaseEnabled: true,
                              domStorageEnabled: true,
                              builtInZoomControls: false,
                              displayZoomControls: false,
                              safeBrowsingEnabled: true,
                              clearSessionCache: !kIsWeb,
                              loadsImagesAutomatically: true,
                              thirdPartyCookiesEnabled: true,
                              blockNetworkImage: false,
                              supportMultipleWindows: true,
                            ),
                            ios: IOSInAppWebViewOptions(
                              allowsInlineMediaPlayback: true,
                            ),
                            crossPlatform: InAppWebViewOptions(
                              javaScriptEnabled: true,
                              // ← true enables onDownloadStartRequest
                              useOnDownloadStart: true,
                              allowFileAccessFromFileURLs: true,
                              allowUniversalAccessFromFileURLs: true,
                              mediaPlaybackRequiresUserGesture: true,
                            ),
                          ),
                          initialUserScripts: UnmodifiableListView([
                            UserScript(
                              source: """
                                if (typeof Notification === "undefined") {
                                  window.Notification = function(title, options) {};
                                  window.Notification.permission = "granted";
                                  window.Notification.requestPermission = function(cb) {
                                    if (cb) cb("granted");
                                    return Promise.resolve("granted");
                                  };
                                }
                              """,
                              injectionTime:
                                  UserScriptInjectionTime.AT_DOCUMENT_START,
                            ),
                          ]),
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                            _controller.complete(controller);
                          },
                          pullToRefreshController: pullToRefreshController,
                          onLoadStart: (_, __) =>
                              setState(() => isLoading = true),
                          onLoadStop: (_, __) {
                            setState(() => isLoading = false);
                            pullToRefreshController?.endRefreshing();
                          },
                          onProgressChanged: (_, progress) {
                            if (progress == 100) {
                              setState(() => isLoading = false);
                              pullToRefreshController?.endRefreshing();
                            }
                          },
                          onReceivedError: (_, __, ___) {
                            pullToRefreshController?.endRefreshing();
                            setState(() => isLoading = false);
                          },
                          onReceivedHttpError: (controller, _, error) {
                            if (error.statusCode == 409) controller.reload();
                            pullToRefreshController?.endRefreshing();
                            setState(() => isLoading = false);
                          },

                          // ── DOWNLOAD HANDLER ─────────────────
                          onDownloadStartRequest: (controller, request) async {
                            final filename = resolveFilename(
                              request.url.toString(),
                              request.contentDisposition,
                              request.mimeType,
                            );
                            await _downloadManager.enqueue(
                              context,
                              request.url.toString(),
                              filename,
                            );
                          },

                          shouldOverrideUrlLoading: (controller, action) async {
                            final uri = action.request.url!;
                            if (uri.scheme == 'tel' ||
                                uri.scheme == 'mailto' ||
                                uri.scheme == 'whatsapp' ||
                                uri.toString().contains(
                                  'accounts.google.com',
                                )) {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }
                            return NavigationActionPolicy.ALLOW;
                          },

                          onConsoleMessage: (_, msg) {
                            if (kDebugMode) {
                              debugPrint(
                                'WV Console [${msg.messageLevel}]: ${msg.message}',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // ── Loading overlay ───────────────────────────
                  if (isLoading)
                    Container(
                      height: screenHeight,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color(0xFF001f3f),
                            Color(0xFF003366),
                            Color(0xFF004080),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),

                  // ── Download tray ─────────────────────────────
                  DownloadTray(manager: _downloadManager),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
