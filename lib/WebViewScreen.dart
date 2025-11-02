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

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebERPState();
}

class _WebERPState extends State<WebViewScreen> {
  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  bool isLoading = true;
  String url = "https://fvagito.com/";
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  PullToRefreshSettings pullToRefreshSettings = PullToRefreshSettings();
  bool pullToRefreshEnabled = true;
  bool _isNoInternetScreenVisible = false;
  final GlobalKey webViewKey = GlobalKey();

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: pullToRefreshSettings,
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
    super.initState();
  }

  @override
  void dispose() {
    // This helps even if user presses back manually
    final parentState = context.findAncestorStateOfType<_WebERPState>();
    if (parentState != null) {
      parentState._isNoInternetScreenVisible = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenheight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController!.canGoBack()) {
          webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xffFED700),
        body: BlocListener<InternetStatusBloc, InternetStatusState>(
          listener: (context, state) async {
            if (state is InternetStatusLostState &&
                !_isNoInternetScreenVisible) {
              _isNoInternetScreenVisible = true;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Nointernet()),
              );
              // When user returns manually
              _isNoInternetScreenVisible = false;
            } else if (state is InternetStatusBackState &&
                _isNoInternetScreenVisible) {
              Navigator.pop(context); // Close Nointernet screen
              _isNoInternetScreenVisible = false;
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: <Widget>[
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
                            useOnDownloadStart: true,
                            allowFileAccessFromFileURLs: true,
                            allowUniversalAccessFromFileURLs: true,
                            mediaPlaybackRequiresUserGesture: true,
                          ),
                        ),
                        initialUserScripts: UnmodifiableListView<UserScript>([
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
                        onWebViewCreated: (controller) {
                          webViewController = controller;
                          _controller.complete(controller);
                          // if (!kIsWeb) {
                          //   controller.clearCache();
                          // }
                        },
                        pullToRefreshController: pullToRefreshController,
                        onLoadStart: (controller, url) {
                          setState(() {
                            isLoading = true;
                          });
                        },
                        onLoadStop: (controller, url) {
                          setState(() {
                            isLoading = false;
                          });
                          pullToRefreshController?.endRefreshing();
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                              var uri = navigationAction.request.url!;
                              if (uri.scheme == "tel" ||
                                  uri.scheme == "mailto" ||
                                  uri.scheme == "whatsapp" ||
                                  uri.toString().contains(
                                    "accounts.google.com",
                                  )) {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                  return NavigationActionPolicy.CANCEL;
                                }
                              }
                              return NavigationActionPolicy.ALLOW;
                            },
                        onReceivedError: (controller, request, error) {
                          pullToRefreshController?.endRefreshing();
                          setState(() {
                            isLoading = false;
                          });
                        },
                        onProgressChanged: (controller, progress) {
                          if (progress == 100) {
                            setState(() {
                              isLoading = false;
                            });
                            pullToRefreshController?.endRefreshing();
                          }
                        },
                        onReceivedHttpError: (controller, request, error) {
                          if (error.statusCode == 409) {
                            controller.reload();
                          }
                          pullToRefreshController?.endRefreshing();
                          setState(() {
                            isLoading = false;
                          });
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          if (kDebugMode) {
                            debugPrint(
                              "Console message: ${consoleMessage.toString()}",
                            );
                            debugPrint(
                              "Message: ${consoleMessage.message}, Level: ${consoleMessage.messageLevel}",
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (isLoading)
                  Container(
                    height: screenheight,
                    color:  Color(0xffFED700),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
