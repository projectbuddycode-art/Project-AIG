import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';

class CaptureController {
  final CameraEngine _engine;

  CaptureController(this._engine);

  Future<CaptureResult> capturePhoto(CaptureSettings settings) async {
    return _engine.capturePhoto(settings);
  }

  Future<void> startVideo(CaptureSettings settings) async =>
      _engine.startVideo(settings);

  Future<CaptureResult> stopVideo() async => _engine.stopVideo();
}
