import 'package:flutter/foundation.dart';

enum CameraLifecycleState {
  idle,
  permissionRequired,
  initializing,
  previewStarting,
  previewActive,
  capturingPhoto,
  recordingVideo,
  savingMedia,
  recovering,
  unavailable,
  error,
  disposed,
}

@immutable
class CameraState {
  final CameraLifecycleState status;
  final bool isInitialized;
  final bool isPreviewing;
  final double zoom;
  final double focus;
  final double exposure;
  final String flashMode;

  const CameraState({
    required this.status,
    required this.isInitialized,
    required this.isPreviewing,
    required this.zoom,
    required this.focus,
    required this.exposure,
    required this.flashMode,
  });

  const CameraState.uninitialized()
    : status = CameraLifecycleState.idle,
      isInitialized = false,
      isPreviewing = false,
      zoom = 1.0,
      focus = 0.0,
      exposure = 0.0,
      flashMode = 'auto';

  bool get isReady => status == CameraLifecycleState.previewActive;

  CameraState copyWith({
    CameraLifecycleState? status,
    bool? isInitialized,
    bool? isPreviewing,
    double? zoom,
    double? focus,
    double? exposure,
    String? flashMode,
  }) {
    final nextStatus = status ?? this.status;
    final nextInitialized = isInitialized ?? this.isInitialized;
    final nextPreviewing = isPreviewing ?? this.isPreviewing;
    return CameraState(
      status: nextStatus,
      isInitialized: nextInitialized,
      isPreviewing: nextPreviewing,
      zoom: zoom ?? this.zoom,
      focus: focus ?? this.focus,
      exposure: exposure ?? this.exposure,
      flashMode: flashMode ?? this.flashMode,
    );
  }
}
