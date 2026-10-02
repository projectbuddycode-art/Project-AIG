import 'package:aig/features/camera/engines/camera_engine.dart';

class FlashController {
  final CameraEngine _engine;

  FlashController(this._engine);

  Future<void> setFlashMode(String mode) async {
    await _engine.setFlashMode(mode);
  }

  Future<void> torchOn() async {
    await _engine.setFlashMode('torch');
  }

  Future<void> torchOff() async {
    await _engine.setFlashMode('off');
  }
}
