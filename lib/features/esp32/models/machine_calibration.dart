/// Motor geometry for DiamondCam.
/// DM542 DIP contract is 3200 pulses/revolution (1/16 microstep). Physical CW
/// from the camera view is still unconfirmed, so [isCalibrationConfirmed]
/// stays false until [positiveDirectionIsCW] is set.
class MachineCalibration {
  const MachineCalibration({
    this.motorStepAngle = 1.8,
    this.microsteps,
    this.gearRatio = 1.0,
    this.positiveDirectionIsCW,
    this.hasHomeSensor = false,
    this.hasLimitSensor = false,
    this.minAngle = 0,
    this.maxAngle = 180,
    this.maxSpeed = 100,
    this.maxLightIntensity = 100,
  });

  final double motorStepAngle;
  final int? microsteps;
  final double gearRatio;
  final bool? positiveDirectionIsCW;
  final bool hasHomeSensor;
  final bool hasLimitSensor;
  final double minAngle;
  final double maxAngle;
  final double maxSpeed;
  final int maxLightIntensity;

  static const MachineCalibration current = MachineCalibration();

  bool get isMicrosteppingConfirmed => microsteps != null && microsteps! > 0;

  bool get isPhysicalDirectionConfirmed => positiveDirectionIsCW != null;

  bool get isCalibrationConfirmed =>
      isMicrosteppingConfirmed && isPhysicalDirectionConfirmed && gearRatio > 0;

  String get calibrationStatus => isCalibrationConfirmed ? 'Confirmed' : 'Unconfirmed';

  double get fullStepsPerRevolution => 360 / motorStepAngle;

  double? get stepsPerRevolution {
    if (!isMicrosteppingConfirmed) return null;
    return fullStepsPerRevolution * microsteps! * gearRatio;
  }

  double? get stepsPerDegree {
    final spr = stepsPerRevolution;
    if (spr == null) return null;
    return spr / 360;
  }

  /// Commanded angle uses 3200 pulses/rev. That is not encoder-measured position.
  static const String firmwareAngleScaleNote =
      'Firmware uses 3200 pulses/revolution (8.888889 pulses/degree). Commanded angle is not measured physical position. Physical CW is unconfirmed.';
}
