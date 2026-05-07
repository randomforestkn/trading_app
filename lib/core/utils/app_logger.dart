import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[WARN] $message');
    if (error != null) {
      debugPrint('  error: $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('  error: $error');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
