import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsNavObserver extends NavigatorObserver {
  Future<void> _setScreen(Route<dynamic>? route) async {
    final name = route?.settings.name ?? route?.runtimeType.toString() ?? 'unknown';
    await FirebaseCrashlytics.instance.setCustomKey('current_screen', name);
    FirebaseCrashlytics.instance.log('screen: $name');
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _setScreen(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _setScreen(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _setScreen(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
