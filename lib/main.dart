import 'dart:ui';

import 'package:flutter/material.dart';

import 'app/trading_app.dart';
import 'core/utils/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Uncaught platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
  runApp(const TradingApp());
}
