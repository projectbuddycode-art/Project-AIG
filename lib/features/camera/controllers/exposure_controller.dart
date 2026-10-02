import 'package:aig/features/camera/engines/camera_engine.dart';

class ExposureController {
  final CameraEngine _engine;

  ExposureController(this._engine);

  Future<void> autoExposure() async {
    await _engine.setExposureCompensation(0.0);
  }

  Future<void> setExposureCompensation(double value) async {
    await _engine.setExposureCompensation(value);
  }

  Future<void> lockExposure() async {
    await _engine.setExposureCompensation(0.0);
  }

  Future<void> unlockExposure() async {
    await _engine.setExposureCompensation(0.0);
  }
}
