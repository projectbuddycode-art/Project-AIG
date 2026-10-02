import 'package:flutter/foundation.dart';

@immutable
class LightingConfig {
  final double masterBrightness; // 0.0 - 1.0
  final List<double>? individual; // per-light brightness 0.0 - 1.0
  final int colorTemperature; // in Kelvin
  final bool enabled;
  final Duration fadeDuration;

  const LightingConfig({
    this.masterBrightness = 1.0,
    this.individual,
    this.colorTemperature = 4000,
    this.enabled = true,
    this.fadeDuration = const Duration(milliseconds: 0),
  });

  LightingConfig copyWith({
    double? masterBrightness,
    List<double>? individual,
    int? colorTemperature,
    bool? enabled,
    Duration? fadeDuration,
  }) {
    return LightingConfig(
      masterBrightness: masterBrightness ?? this.masterBrightness,
      individual: individual ?? this.individual,
      colorTemperature: colorTemperature ?? this.colorTemperature,
      enabled: enabled ?? this.enabled,
      fadeDuration: fadeDuration ?? this.fadeDuration,
    );
  }
}
