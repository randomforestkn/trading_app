import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[WARN] ${sanitizeText(message)}');
    if (error != null) {
      debugPrint('  error: ${sanitizeText(error.toString())}');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[ERROR] ${sanitizeText(message)}');
    if (error != null) {
      debugPrint('  error: ${sanitizeText(error.toString())}');
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 8);
    }
  }

  static String sanitizeText(String input) {
    var sanitized = input;
    final patterns = <RegExp>[
      RegExp(
        r'(apikey|api_key|token|access_token|key)=([^&\s]+)',
        caseSensitive: false,
      ),
      RegExp(r'(authorization:\s*)([^,\s]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAllMapped(pattern, (match) {
        final prefix = match.group(1) ?? '';
        final separator = prefix.contains(':') ? ' ' : '=';
        return '$prefix${separator}REDACTED';
      });
    }
    return sanitized;
  }
}
