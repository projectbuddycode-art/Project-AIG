import 'package:aig/features/camera/engines/camera_engine.dart';

class ZoomController {
  final CameraEngine _engine;

  ZoomController(this._engine);

  Future<void> setZoom(double zoom) async {
    await _engine.setZoom(zoom);
  }

  Future<void> smoothZoomTo(double zoom, Duration duration) async {
    await _engine.setZoom(zoom);
  }
}
