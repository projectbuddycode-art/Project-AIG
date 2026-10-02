import 'package:aig/features/esp32/models/rotation_config.dart';
import 'package:aig/features/esp32/models/command_definition.dart';
import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';

/// Responsible for all rotation-related commands and state translation.
///
/// DiamondCam firmware:
/// - POST /rotate {angle: 0..180, speed}
/// - POST /rotate/continuous {direction: "cw"|other, speed}
/// - POST /rotate/stop
/// - No /home and no home sensor. [home] is unsupported.
class RotationController {
  final CommandExecutor _executor;

  /// Last commanded angle (firmware reports commanded angle, not encoder).
  double _commandedAngle = 0;

  RotationController(this._executor);

  double get commandedAngle => _commandedAngle;

  void syncCommandedAngle(double angle) {
    _commandedAngle = angle.clamp(MachineEndpointConfig.minAngle, MachineEndpointConfig.maxAngle);
  }

  Future<void> start(RotationConfig config) async {
    final payload = _buildRotationPayload(CommandDefinition.rotate.commandId, config);
    final cmd = DeviceCommand(type: DeviceCommandType.rotation, payload: payload);
    await _executor.enqueue(cmd);
  }

  Future<void> stop() async {
    final payload = [CommandDefinition.rotate.commandId, 0x00];
    final cmd = DeviceCommand(type: DeviceCommandType.rotation, payload: payload);
    await _executor.enqueue(cmd, urgent: true);
  }

  Future<void> pause() async {
    await stop();
  }

  Future<void> resume() async {
    // Firmware has no pause/resume — restart continuous CW as a conservative default.
    await start(const RotationConfig(speed: 5, clockwise: true, continuous: true));
  }

  /// Relative step mapped to absolute firmware angle (0..180).
  /// Positive degrees → increase angle (RIGHT / CW convention pending hardware confirm).
  /// Negative degrees → decrease angle (LEFT / CCW).
  Future<void> step(double degrees, RotationConfig config) async {
    final next = (_commandedAngle + degrees).clamp(
      MachineEndpointConfig.minAngle,
      MachineEndpointConfig.maxAngle,
    );
    await goToAngle(next, config);
  }

  Future<void> goToAngle(double angle, RotationConfig config) async {
    final normalized = angle.clamp(MachineEndpointConfig.minAngle, MachineEndpointConfig.maxAngle);
    _commandedAngle = normalized;
    final int angleInt = normalized.round();
    final speed = (config.speed * 100).clamp(0, 65535).round();
    final payload = <int>[
      CommandDefinition.rotate.commandId,
      0x10,
      angleInt & 0xFF,
      (angleInt >> 8) & 0xFF,
      speed & 0xFF,
      (speed >> 8) & 0xFF,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.rotation, payload: payload));
  }

  /// Home is unavailable: no sensor and no /home endpoint.
  Future<void> home() async {
    throw UnsupportedError('Home sensor not installed');
  }

  Future<void> emergencyStop() async {
    await stop();
  }

  List<int> _buildRotationPayload(int commandId, RotationConfig config, {bool isStep = false}) {
    final dir = config.clockwise ? 1 : 0;
    final continuous = config.continuous ? 1 : 0;
    final speed = (config.speed * 100).clamp(0, 65535).round();
    final payload = <int>[commandId, dir, continuous, speed & 0xFF, (speed >> 8) & 0xFF];
    if (isStep) {
      final angle = _commandedAngle.round().clamp(
        MachineEndpointConfig.minAngle.round(),
        MachineEndpointConfig.maxAngle.round(),
      );
      payload.addAll([angle & 0xFF, (angle >> 8) & 0xFF]);
    }
    return payload;
  }
}
