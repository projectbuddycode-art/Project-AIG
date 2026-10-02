import 'package:flutter/foundation.dart';

class LoggingService {
  const LoggingService();

  void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
