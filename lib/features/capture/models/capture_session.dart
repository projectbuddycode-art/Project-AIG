import 'package:flutter/foundation.dart';

import 'package:aig/features/camera/models/camera_settings.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

@immutable
class CaptureSession {
  final String id;
  final CaptureMode mode;
  final CameraSettings cameraSettings;
  final CaptureSettings captureSettings;
  final String description;
  final String? presetId;
  final JewelryProcessingLook? lookOverride;
  final int? filterStrength;
  final bool? lightOnOverride;
  final int? lightIntensityOverride;

  const CaptureSession({
    required this.id,
    required this.mode,
    this.cameraSettings = const CameraSettings(),
    this.captureSettings = const CaptureSettings(),
    this.description = '',
    this.presetId,
    this.lookOverride,
    this.filterStrength,
    this.lightOnOverride,
    this.lightIntensityOverride,
  });
}
