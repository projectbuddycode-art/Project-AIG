import 'dart:async';
import 'dart:ui';

import 'package:aig/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  debugPrint('[AIG_STARTUP] main entered');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[AIG_STARTUP] Flutter binding initialized');

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[AIG_ERROR] ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
    return const ColoredBox(
      color: Color(0xFF111111),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This screen could not be displayed. Return to the dashboard and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFEDEDED), fontSize: 16),
          ),
        ),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Uncaught platform error: $error');
    debugPrint('$stack');
    return true;
  };

  runZonedGuarded<Future<void>>(
    () async {
      runApp(const ProviderScope(child: App()));
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught zone error: $error');
      debugPrint('$stack');
    },
  );
}
