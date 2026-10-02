import 'package:flutter/foundation.dart';

@immutable
class RotationConfig {
  final double speed; // degrees per second or relative unit
  final bool clockwise;
  final bool continuous;
  final double stepDegrees;

  const RotationConfig({
    this.speed = 0.0,
    this.clockwise = true,
    this.continuous = false,
    this.stepDegrees = 1.0,
  });

  RotationConfig copyWith({double? speed, bool? clockwise, bool? continuous, double? stepDegrees}) {
    return RotationConfig(
      speed: speed ?? this.speed,
      clockwise: clockwise ?? this.clockwise,
      continuous: continuous ?? this.continuous,
      stepDegrees: stepDegrees ?? this.stepDegrees,
    );
  }
}
