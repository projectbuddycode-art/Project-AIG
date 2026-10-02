import 'dart:async';

import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/camera_capabilities.dart';
import 'package:aig/features/camera/models/camera_settings.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';

/// Platform-independent camera engine interface.
class CameraPermissionException implements Exception {
  const CameraPermissionException([
    this.message = 'Camera permission was not granted.',
  ]);

  final String message;

  @override
  String toString() => 'CameraPermissionException: $message';
}

class CameraUnavailableException implements Exception {
  const CameraUnavailableException([
    this.message = 'No usable camera is available on this device.',
  ]);

  final String message;

  @override
  String toString() => 'CameraUnavailableException: $message';
}

abstract class CameraEngine {
  /// Initialize engine and resources.
  Future<void> initialize();

  /// Dispose engine resources.
  Future<void> dispose();

  /// Start preview and return a broadcast stream of frames.
  Stream<CameraFrame> get previewStream;

  /// Start preview (allocates resources if necessary).
  Future<void> startPreview();

  /// True while a native/local preview session is owned by this engine.
  bool get isPreviewing;

  /// Stop preview.
  Future<void> stopPreview();

  /// Capture a photo using given settings.
  Future<CaptureResult> capturePhoto(CaptureSettings settings);

  /// Start video recording to a temporary location.
  Future<void> startVideo(CaptureSettings settings);

  /// Stop video recording and return final capture result.
  Future<CaptureResult> stopVideo();

  /// Switch camera (front/back or lens id).
  Future<void> switchCamera();

  /// Apply a zoom level to the active camera.
  Future<void> setZoom(double zoom);

  /// Apply exposure compensation to the active camera.
  Future<void> setExposureCompensation(double value);

  /// Trigger autofocus on the active camera.
  Future<void> autoFocus({double x = 0.5, double y = 0.5});

  /// Apply a flash mode to the active camera.
  Future<void> setFlashMode(String mode);

  /// Current camera capabilities.
  CameraCapabilities get capabilities;

  /// Current active settings.
  CameraSettings get settings;
}
