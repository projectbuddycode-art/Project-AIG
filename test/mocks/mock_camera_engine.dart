import 'dart:async';
import 'dart:typed_data';

import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/camera_capabilities.dart';
import 'package:aig/features/camera/models/camera_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';
import 'package:aig/features/camera/models/capture_settings.dart';

class MockCameraEngine implements CameraEngine {
  final _ctrl = StreamController<CameraFrame>.broadcast();
  bool _previewing = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    await _ctrl.close();
  }

  @override
  Stream<CameraFrame> get previewStream => _ctrl.stream;

  @override
  bool get isPreviewing => _previewing;

  @override
  Future<void> startPreview() async {
    _previewing = true;
    // emit a sample frame
    _ctrl.add(CameraFrame(timestamp: DateTime.now(), bytes: Uint8List.fromList([0, 1, 2, 3]), width: 16, height: 16));
  }

  @override
  Future<void> stopPreview() async {
    _previewing = false;
  }

  @override
  Future<CaptureResult> capturePhoto(CaptureSettings settings) async {
    return CaptureResult(timestamp: DateTime.now(), jpeg: Uint8List.fromList([0xFF, 0xD8, 0xFF]), width: 16, height: 16);
  }

  @override
  Future<void> startVideo(CaptureSettings settings) async {}

  @override
  Future<CaptureResult> stopVideo() async => CaptureResult(timestamp: DateTime.now());

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> setZoom(double zoom) async {}

  @override
  Future<void> setExposureCompensation(double value) async {}

  @override
  Future<void> autoFocus({double x = 0.5, double y = 0.5}) async {}

  @override
  Future<void> setFlashMode(String mode) async {}

  @override
  CameraCapabilities get capabilities => const CameraCapabilities(hasFlash: true);

  @override
  CameraSettings get settings => const CameraSettings();
}
