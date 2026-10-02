/// Typed GET /info payload. Unknown hardware fields stay null — never invented.
class MachineInfo {
  const MachineInfo({
    this.machineId,
    this.firmware,
    this.motorStepAngle,
    this.gearRatio,
    this.microsteps,
    this.stepsPerRevolution,
    this.stepsPerDegree,
    this.pulsesPerRevolution,
    this.pulsesPerDegree,
    this.positiveDirectionIsCW,
    this.calibrationConfirmed = false,
    this.hasHomeSensor = false,
    this.hasLimitSensor = false,
    this.raw,
  });

  final String? machineId;
  final String? firmware;
  final num? motorStepAngle;
  final num? gearRatio;
  final int? microsteps;
  final num? stepsPerRevolution;
  final num? stepsPerDegree;
  final num? pulsesPerRevolution;
  final num? pulsesPerDegree;
  final bool? positiveDirectionIsCW;
  final bool calibrationConfirmed;
  final bool hasHomeSensor;
  final bool hasLimitSensor;
  final Map<String, dynamic>? raw;

  String get machineIdLabel {
    if (machineId == null || machineId!.trim().isEmpty) {
      return 'Unavailable';
    }
    final id = machineId!.trim();
    if (id == '192.168.4.1' || id.startsWith('http://192.168.4.1')) {
      return 'Unavailable (IP is not a Machine ID)';
    }
    return id;
  }

  String get firmwareLabel =>
      (firmware == null || firmware!.trim().isEmpty) ? 'Unavailable' : firmware!.trim();

  String get microstepsLabel => microsteps == null ? 'Unconfirmed' : '$microsteps';

  String get directionLabel {
    if (positiveDirectionIsCW == null) return 'Unconfirmed';
    return positiveDirectionIsCW! ? 'Positive = CW' : 'Positive = CCW';
  }

  String get calibrationLabel => calibrationConfirmed ? 'Confirmed' : 'Unconfirmed';

  String get homeLabel => hasHomeSensor ? 'Installed' : 'Not installed';

  String get limitLabel => hasLimitSensor ? 'Installed' : 'Not installed';
}
