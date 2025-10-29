import 'dart:async';
import 'dart:convert';
import 'dart:developer' as AppLogger;
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pipemantra/services/ApiClient.dart';
import 'package:pipemantra/services/SecureStorageService.dart';
import 'package:pipemantra/utils/media_query_helper.dart';
import 'app_routes/router.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',

  importance: Importance.high,
  playSound: true,
);

// Background handler MUST be a top-level function and annotated.
@pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // optionally log/route background payloads
// }

void main() {
  // Optional in dev: make zone mistakes fatal
  // BindingBase.debugZoneErrorsAreFatal = true;
  runZonedGuarded(
        () async {
      // Everything below runs in the SAME zone as runApp()
      WidgetsFlutterBinding.ensureInitialized();

      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );

      // Crashlytics hooks
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterError(details);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      Isolate.current.addErrorListener(
        RawReceivePort((pair) async {
          final List<dynamic> errorAndStacktrace = pair;
          await FirebaseCrashlytics.instance.recordError(
            errorAndStacktrace.first,
            errorAndStacktrace.last,
            fatal: true,
          );
        }).sendPort,
      );

      // Bloc observer (if you use BLoC/Cubit)
      // Bloc.observer = CrashlyticsBlocObserver();

      // API interceptors
      ApiClient.setupInterceptors();

      // Orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // FCM — register background handler BEFORE any onMessage listeners
      // FirebaseMessaging.onBackgroundMessage(
      //   _firebaseMessagingBackgroundHandler,
      // );

      final messaging = FirebaseMessaging.instance;

      // iOS permission request
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (Platform.isIOS) {
        final apnsToken = await messaging.getAPNSToken();
        AppLogger.log("APNs Token: $apnsToken");
      }

      // Get FCM token
      final fcmToken = await messaging.getToken();
      AppLogger.log("FCM Token: $fcmToken");
      if (fcmToken != null) {
        await SecureStorageService.instance.setString("fb_token", fcmToken);
      }

      // Foreground presentation (iOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Local notifications init
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: iosInit,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
          // Handle notification tap routing via navigatorKey / go_router
        },
      );

      // Create Android notification channel (Android 8.0+)
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
      >()
          ?.createNotificationChannel(channel);

      // Foreground messages → show local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
          showNotification(notification, android, message.data);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle launches from tray taps
      });

      runApp(const MyApp()); // ✅ same zone as everything above
    },
        (error, stack) async {
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

// Show a local notification for a foreground FCM
void showNotification(
    RemoteNotification notification,
    AndroidNotification android,
    Map<String, dynamic> data,
    ) async {
  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    details,
    payload: jsonEncode(data),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return MaterialApp.router(
      title: 'PipeMantra',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        scaffoldBackgroundColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        cardColor: Colors.white,
        searchBarTheme: const SearchBarThemeData(),
        tabBarTheme: const TabBarThemeData(),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(
            color: Colors.black38,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: "segeo",
          ),
          labelStyle: const TextStyle(
            color: Colors.black38,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: "segeo",
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xffE5E7EB), width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xffE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xffE5E7EB), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xffE5E7EB), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xffE5E7EB), width: 1),
          ),
          errorStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        ),
        dialogTheme: const DialogThemeData(
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
        ),
        buttonTheme: const ButtonThemeData(),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          shadowColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(surfaceTintColor: Colors.white),
        cardTheme: CardThemeData(
          shadowColor: Colors.white,
          surfaceTintColor: Colors.white,
          color: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(style: ButtonStyle()),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle()),
        outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle()),
        bottomSheetTheme: const BottomSheetThemeData(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.light(
          background: Colors.white,
        ).copyWith(background: Colors.white),
        fontFamily: 'segeo',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}

//
// import 'dart:async';
// import 'dart:convert';
// import 'dart:isolate';
// import 'dart:ui';
// import 'dart:io' show Platform;
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:provider/provider.dart';
// import 'package:mentivisor/services/ApiClient.dart';
// import 'package:mentivisor/services/SecureStorageService.dart';
// import 'package:mentivisor/utils/AppLogger.dart';
// import 'package:mentivisor/utils/media_query_helper.dart';
// import 'StateInjector.dart';
// import 'app_routes/router.dart';
// import 'firebase_options.dart';
//
// // Only available for mobile (Android/iOS)
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// // Initialize the notification plugin (mobile only)
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// FlutterLocalNotificationsPlugin();
//
// const AndroidNotificationChannel channel = AndroidNotificationChannel(
//   'high_importance_channel',
//   'High Importance Notifications',
//   description: 'This channel is used for important notifications.',
//   importance: Importance.high,
//   playSound: true,
// );
//
// /// Background FCM handler (MUST be top-level)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   AppLogger.log("BG message received: ${message.messageId}");
// }
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   // Crashlytics (disabled for web)
//   if (!kIsWeb) {
//     FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
//
//     PlatformDispatcher.instance.onError = (error, stack) {
//       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
//       return true;
//     };
//
//     Isolate.current.addErrorListener(
//       RawReceivePort((pair) async {
//         final List<dynamic> errorAndStacktrace = pair;
//         await FirebaseCrashlytics.instance.recordError(
//           errorAndStacktrace.first,
//           errorAndStacktrace.last,
//           fatal: true,
//         );
//       }).sendPort,
//     );
//   }
//
//   // Setup interceptors
//   ApiClient.setupInterceptors();
//
//   // Orientation (mobile only)
//   if (!kIsWeb) {
//     await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   }
//
//   // FCM configuration
//   await setupFirebaseMessaging();
//
//   runApp(const MyApp());
// }
//
// Future<void> setupFirebaseMessaging() async {
//   final messaging = FirebaseMessaging.instance;
//
//   if (kIsWeb) {
//     // ✅ Web handling (no local notifications)
//     AppLogger.log("Running on Web (Chrome)");
//     try {
//       final token = await messaging.getToken(
//         vapidKey: "YOUR_WEB_VAPID_KEY_HERE",
//       );
//       AppLogger.log("FCM Web Token: $token");
//     } catch (e) {
//       AppLogger.log("Error getting web FCM token: $e");
//     }
//     return;
//   }
//
//   // ✅ Mobile handling
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//   await messaging.requestPermission(alert: true, badge: true, sound: true);
//
//   final token = await messaging.getToken();
//   AppLogger.log("FCM Token: $token");
//
//   if (token != null) {
//     await SecureStorageService.instance.setString("fb_token", token);
//   }
//
//   // Initialize local notifications (mobile only)
//   const iosInit = DarwinInitializationSettings(
//     requestAlertPermission: true,
//     requestBadgePermission: true,
//     requestSoundPermission: true,
//   );
//   const initSettings = InitializationSettings(
//     android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//     iOS: iosInit,
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) async {
//       AppLogger.log("Notification clicked: ${response.payload}");
//     },
//   );
//
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);
//
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     final notification = message.notification;
//     final android = message.notification?.android;
//     if (notification != null && android != null) {
//       showNotification(notification, android, message.data);
//     }
//   });
//
//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     AppLogger.log("Opened from notification: ${message.data}");
//   });
// }
//
// void showNotification(
//     RemoteNotification notification,
//     AndroidNotification android,
//     Map<String, dynamic> data,
//     ) async {
//   final androidDetails = AndroidNotificationDetails(
//     channel.id,
//     channel.name,
//     channelDescription: channel.description,
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     icon: '@mipmap/ic_launcher',
//   );
//
//   final details = NotificationDetails(android: androidDetails);
//
//   await flutterLocalNotificationsPlugin.show(
//     notification.hashCode,
//     notification.title,
//     notification.body,
//     details,
//     payload: jsonEncode(data),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     SizeConfig.init(context);
//     return MultiRepositoryProvider(
//       providers: StateInjector.repositoryProviders,
//       child: MultiProvider(
//         providers: StateInjector.blocProviders,
//         child: MaterialApp.router(
//           title: 'MentiVisor',
//           debugShowCheckedModeBanner: false,
//           theme: ThemeData(
//             scaffoldBackgroundColor: Colors.white,
//             colorScheme: const ColorScheme.light(background: Colors.white),
//             fontFamily: 'segeo',
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           routerConfig: appRouter,
//         ),
//       ),
//     );
//   }
// }
