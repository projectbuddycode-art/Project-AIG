import 'dart:async';

import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/controllers/capture_controller.dart';
import 'package:aig/features/camera/controllers/focus_controller.dart';
import 'package:aig/features/camera/controllers/exposure_controller.dart';
import 'package:aig/features/camera/controllers/zoom_controller.dart';
import 'package:aig/features/camera/controllers/flash_controller.dart';
import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/camera_settings.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';
import 'package:aig/features/esp32/controllers/machine_controller.dart';

/// High-level camera controller that orchestrates subsystems and communicates with MachineController only.
class CameraController {
  final CameraEngine _engine;
  final CaptureController capture;
  final FocusController focus;
  final ExposureController exposure;
  final ZoomController zoom;
  final FlashController flash;
  final MachineController _machine;

  CameraController._(
    this._engine,
    this.capture,
    this.focus,
    this.exposure,
    this.zoom,
    this.flash,
    this._machine,
  );

  factory CameraController(CameraEngine engine, MachineController machine) {
    final cap = CaptureController(engine);
    final foc = FocusController(engine);
    final exp = ExposureController(engine);
    final zom = ZoomController(engine);
    final fl = FlashController(engine);
    return CameraController._(engine, cap, foc, exp, zom, fl, machine);
  }

  Stream<CameraFrame> get preview => _engine.previewStream;

  CameraSettings get settings => _engine.settings;

  bool get isPreviewing => _engine.isPreviewing;

  Future<void> initialize() => _engine.initialize();

  Future<void> dispose() => _engine.dispose();

  Future<void> startPreview() => _engine.startPreview();

  Future<void> stopPreview() => _engine.stopPreview();

  Future<CaptureResult> capturePhoto(CaptureSettings settings) async {
    return capture.capturePhoto(settings);
  }

  MachineController get machine => _machine;

  Future<void> switchCamera() => _engine.switchCamera();
}
