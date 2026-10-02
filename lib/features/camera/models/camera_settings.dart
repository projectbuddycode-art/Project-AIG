import 'package:flutter/foundation.dart';

@immutable
class CameraSettings {
  final double zoom;
  final double exposureCompensation;
  final double focusDistance;
  final String activeLens; // identifier of lens
  final String flashMode; // 'auto'|'off'|'on'|'torch'

  const CameraSettings({
    this.zoom = 1.0,
    this.exposureCompensation = 0.0,
    this.focusDistance = 0.0,
    this.activeLens = 'back',
    this.flashMode = 'auto',
  });

  CameraSettings copyWith({
    double? zoom,
    double? exposureCompensation,
    double? focusDistance,
    String? activeLens,
    String? flashMode,
  }) {
    return CameraSettings(
      zoom: zoom ?? this.zoom,
      exposureCompensation: exposureCompensation ?? this.exposureCompensation,
      focusDistance: focusDistance ?? this.focusDistance,
      activeLens: activeLens ?? this.activeLens,
      flashMode: flashMode ?? this.flashMode,
    );
  }
}
