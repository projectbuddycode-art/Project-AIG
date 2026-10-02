import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const String name = 'AIG';
  static const String environment = 'production';

  // Temporary local test bypass. Defaults to false in production.
  // Pass --dart-define=AIG_TEST_MODE=true for local testing only.
  static const bool enableLocalTestingMode = bool.fromEnvironment(
    'AIG_TEST_MODE',
    defaultValue: kDebugMode,
  );
}
