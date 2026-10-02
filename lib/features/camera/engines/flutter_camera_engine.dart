import 'dart:async';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/camera_capabilities.dart';
import 'package:aig/features/camera/models/camera_settings.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';

class FlutterCameraEngine implements CameraEngine {
  final StreamController<CameraFrame> _frameController =
      StreamController.broadcast();
  final CameraCapabilities _capabilities = const CameraCapabilities(
    hasFlash: true,
  );
  CameraSettings _settings = const CameraSettings();
  Timer? _ticker;

  @override
  Future<void> initialize() async {
    _emitFrame();
  }

  @override
  Future<void> dispose() async {
    await stopPreview();
    await _frameController.close();
  }

  @override
  Stream<CameraFrame> get previewStream => _frameController.stream;

  @override
  bool get isPreviewing => _ticker != null;

  @override
  Future<void> startPreview() async {
    if (_ticker != null) return;
    _emitFrame();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _emitFrame();
    });
  }

  @override
  Future<void> stopPreview() async {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<CaptureResult> capturePhoto(CaptureSettings settings) async {
    final width = settings.targetWidth > 0 ? settings.targetWidth : 640;
    final height = settings.targetHeight > 0 ? settings.targetHeight : 480;
    final bytes = _buildJpeg(width, height, jpegQuality: settings.jpegQuality);
    return CaptureResult(
      timestamp: DateTime.now(),
      jpeg: bytes,
      width: width,
      height: height,
    );
  }

  @override
  Future<void> startVideo(CaptureSettings settings) async {
    _emitFrame();
  }

  @override
  Future<CaptureResult> stopVideo() async {
    return CaptureResult(timestamp: DateTime.now());
  }

  @override
  Future<void> switchCamera() async {
    _settings = _settings.copyWith(
      activeLens: _settings.activeLens == 'back' ? 'front' : 'back',
    );
  }

  @override
  Future<void> setZoom(double zoom) async {
    _settings = _settings.copyWith(zoom: zoom.clamp(1.0, 8.0));
  }

  @override
  Future<void> setExposureCompensation(double value) async {
    _settings = _settings.copyWith(
      exposureCompensation: value.clamp(-3.0, 3.0),
    );
  }

  @override
  Future<void> autoFocus({double x = 0.5, double y = 0.5}) async {
    _settings = _settings.copyWith(focusDistance: (x + y) / 2);
  }

  @override
  Future<void> setFlashMode(String mode) async {
    _settings = _settings.copyWith(flashMode: mode);
  }

  @override
  CameraCapabilities get capabilities => _capabilities;

  @override
  CameraSettings get settings => _settings;

  void _emitFrame() {
    final bytes = _buildJpeg(640, 480, jpegQuality: 85);
    _frameController.add(
      CameraFrame(
        timestamp: DateTime.now(),
        bytes: bytes,
        width: 640,
        height: 480,
      ),
    );
  }

  Uint8List _buildJpeg(int width, int height, {required int jpegQuality}) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final red = ((x / width) * 255).round();
        final green = ((y / height) * 255).round();
        final blue = 200 - ((x + y) % 40) * 3;
        image.setPixelRgba(x, y, red, green, blue, 255);
      }
    }
    return img.encodeJpg(image, quality: jpegQuality.clamp(1, 100));
  }
}
