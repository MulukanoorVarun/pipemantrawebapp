import 'package:flutter/foundation.dart';

class LogHelper {
  static void printLog(String tag, dynamic message) {
    if (kDebugMode) {
      print('$tag: $message');
    }
  }
}


