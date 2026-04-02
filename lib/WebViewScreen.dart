import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Nointernet.dart';
import 'bloc/internet_status/internet_status_bloc.dart';
import 'download_manager.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebERPState();
}

class _WebERPState extends State<WebViewScreen> {
  static const String _url = 'https://m.pipemantra.com/';

  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  bool _isLoading = true;
  bool _isNoInternetScreenVisible = false;
  int _progress = 0;
  final DownloadManager _downloadManager = DownloadManager();
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await _webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
    // Trigger initial connectivity check
    context.read<InternetStatusBloc>().add(CheckInternetEvent());
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadUpdate);
    super.dispose();
  }

  void _onDownloadUpdate() {
    // Triggers rebuild only when download state changes
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_webViewController != null &&
            await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
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
          child: BlocListener<InternetStatusBloc, InternetStatusState>(
            listener: (context, state) async {
              if (state is InternetStatusLostState &&
                  !_isNoInternetScreenVisible) {
                _isNoInternetScreenVisible = true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Nointernet()),
                );
                // When user returns manually via back or retry
                _isNoInternetScreenVisible = false;
                // Reload WebView when coming back from no-internet screen
                _webViewController?.reload();
              } else if (state is InternetStatusBackState &&
                  _isNoInternetScreenVisible) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
                _isNoInternetScreenVisible = false;
                // Reload WebView after connectivity restored
                _webViewController?.reload();
              }
            },
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Thin progress bar at top
                      if (_isLoading)
                        LinearProgressIndicator(
                          value: _progress > 0 ? _progress / 100 : null,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                          minHeight: 2,
                        ),
                      Expanded(
                        child: InAppWebView(
                          key: _webViewKey,
                          initialUrlRequest:
                              URLRequest(url: WebUri(_url)),
                          initialSettings: InAppWebViewSettings(
                            // Android
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
                            // iOS
                            allowsInlineMediaPlayback: true,
                            // Cross-platform
                            useShouldOverrideUrlLoading: true,
                            javaScriptEnabled: true,
                            useOnDownloadStart: true,
                            allowFileAccessFromFileURLs: true,
                            allowUniversalAccessFromFileURLs: true,
                            mediaPlaybackRequiresUserGesture: true,
                          ),
                          initialUserScripts:
                              UnmodifiableListView<UserScript>([
                            UserScript(
                              source: """
                                if (typeof Notification === "undefined") {
                                  window.Notification = function(title, options) {
                                    console.log("Mock Notification:", title, options);
                                  };
                                  window.Notification.permission = "granted";
                                  window.Notification.requestPermission = function(callback) {
                                    if (callback) callback("granted");
                                    return Promise.resolve("granted");
                                  };
                                }
                              """,
                              injectionTime:
                                  UserScriptInjectionTime.AT_DOCUMENT_START,
                            ),
                          ]),
                          pullToRefreshController: _pullToRefreshController,
                          onWebViewCreated: (controller) {
                            _webViewController = controller;
                          },
                          onLoadStart: (controller, url) {
                            setState(() => _isLoading = true);
                          },
                          onLoadStop: (controller, url) {
                            setState(() => _isLoading = false);
                            _pullToRefreshController?.endRefreshing();
                          },
                          onProgressChanged: (controller, progress) {
                            setState(() {
                              _progress = progress;
                              if (progress == 100) _isLoading = false;
                            });
                            if (progress == 100) {
                              _pullToRefreshController?.endRefreshing();
                            }
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            final uri = navigationAction.request.url!;

                            if (uri.scheme == 'mailto') {
                              try {
                                await launchUrl(
                                  Uri.parse(uri.toString()),
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                debugPrint('Mail launch error: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No email app found'),
                                    ),
                                  );
                                }
                              }
                              return NavigationActionPolicy.CANCEL;
                            }

                            if (uri.scheme == 'tel' ||
                                uri.scheme == 'whatsapp' ||
                                uri.toString().contains(
                                    'accounts.google.com')) {
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                debugPrint('Launch error: $e');
                              }
                              return NavigationActionPolicy.CANCEL;
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          // Handle file downloads (PDF, blob URLs, etc.)
                          onDownloadStartRequest: (controller, request) {
                            final url = request.url.toString();
                            String filename = request.suggestedFilename ??
                                url.split('/').last.split('?').first;
                            if (filename.isEmpty) filename = 'download';
                            _downloadManager.enqueue(
                              context,
                              url,
                              filename,
                              _webViewController,
                            );
                          },
                          // Handle permission requests from web content
                          // (camera, microphone for file uploads, etc.)
                          onPermissionRequest: (controller, request) async {
                            return PermissionResponse(
                              resources: request.resources,
                              action: PermissionResponseAction.GRANT,
                            );
                          },
                          onReceivedError: (controller, request, error) {
                            _pullToRefreshController?.endRefreshing();
                            setState(() => _isLoading = false);
                          },
                          onReceivedHttpError: (controller, request, error) {
                            if (error.statusCode == 409) {
                              controller.reload();
                            }
                            _pullToRefreshController?.endRefreshing();
                            setState(() => _isLoading = false);
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            if (kDebugMode) {
                              debugPrint(
                                'Console: ${consoleMessage.message} '
                                '[${consoleMessage.messageLevel}]',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  // Full-screen loading overlay (initial load only)
                  if (_isLoading && _progress < 15)
                    Container(
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
                        child:
                            CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}