import 'package:firebase_core/firebase_core.dart';

import 'package:aig/core/config/app_config.dart';

class FirebaseInitializer {
  FirebaseInitializer();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (AppConfig.enableLocalTestingMode) {
      _initialized = true;
      return;
    }

    await Firebase.initializeApp();
    _initialized = true;
  }
}
