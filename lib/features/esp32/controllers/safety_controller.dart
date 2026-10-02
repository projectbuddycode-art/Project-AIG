import 'dart:async';

import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/services/command_executor.dart';

class SafetyController {
  SafetyController(CommandExecutor _, this._rotationController);

  final RotationController _rotationController;

  Future<void> emergencyStop() async {
    await _rotationController.stop();
  }

  Future<T> withTimeout<T>(Future<T> Function() operation, Duration timeout) {
    final timer = Timer(timeout, () => throw TimeoutException('Operation timed out'));
    try {
      return operation().whenComplete(() => timer.cancel());
    } catch (e) {
      timer.cancel();
      rethrow;
    }
  }
}
