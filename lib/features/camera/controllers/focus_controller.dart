import 'package:aig/features/camera/engines/camera_engine.dart';

class FocusController {
  final CameraEngine _engine;

  FocusController(this._engine);

  Future<void> autoFocus() async {
    await _engine.autoFocus();
  }

  Future<void> setManualFocus(double distance) async {
    await _engine.autoFocus(
      x: distance.clamp(0.0, 1.0),
      y: distance.clamp(0.0, 1.0),
    );
  }

  Future<void> lockFocus() async {
    await _engine.autoFocus();
  }

  Future<void> unlockFocus() async {
    await _engine.autoFocus();
  }
}
