import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.setCustomKey('bloc', bloc.runtimeType.toString());
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    // optional: keep it light to avoid noise
    super.onChange(bloc, change);
  }
}
