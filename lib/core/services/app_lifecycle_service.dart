import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  AppLifecycleService();

  final List<void Function(AppLifecycleState)> _callbacks = [];

  void registerCallback(void Function(AppLifecycleState) cb) {
    _callbacks.add(cb);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint('App lifecycle state changed: $state');
    }
    for (final cb in _callbacks) {
      try {
        cb(state);
      } catch (e) {
        if (kDebugMode) debugPrint('Lifecycle callback error: $e');
      }
    }
  }
}
