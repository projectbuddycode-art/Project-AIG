import 'package:flutter/foundation.dart';

/// Provides transport-agnostic logging for the device communication layer.
class DeviceLogger {
  const DeviceLogger();

  void log(String message) {
    if (kDebugMode) {
      debugPrint('[DeviceLogger] $message');
    }
  }
}
