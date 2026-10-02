import 'package:aig/features/esp32/models/command_definition.dart';
import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';

/// Lighting commands for DiamondCam firmware: POST /light {state, intensity:0-100}.
class LightingController {
  final CommandExecutor _executor;
  int _lastIntensity = 100;

  LightingController(this._executor);

  int get lastIntensity => _lastIntensity;

  /// [brightness] is 0.0–1.0 UI scale → firmware intensity 0–100.
  Future<void> setMasterBrightness(double brightness, {Duration fade = Duration.zero}) async {
    final intensity = (brightness.clamp(0.0, 1.0) * MachineEndpointConfig.maxIntensity).round();
    _lastIntensity = intensity;
    final payload = <int>[
      CommandDefinition.setLighting.commandId,
      0x01,
      intensity,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.lighting, payload: payload));
  }

  /// Unsupported by DiamondCam firmware — do not invent a request.
  Future<void> setIndividual(List<double> values, {Duration fade = Duration.zero}) async {
    throw UnsupportedError('Zone lighting is not supported by DiamondCam firmware (/light only accepts state + intensity)');
  }

  /// Unsupported by DiamondCam firmware — do not invent a request.
  Future<void> setColorTemperature(int kelvin, {Duration fade = Duration.zero}) async {
    throw UnsupportedError('Color temperature is not supported by DiamondCam firmware');
  }

  Future<void> on() async {
    final intensity = _lastIntensity <= 0 ? MachineEndpointConfig.maxIntensity : _lastIntensity;
    _lastIntensity = intensity;
    final payload = [
      CommandDefinition.setLighting.commandId,
      0x10,
      0x01,
      intensity,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.lighting, payload: payload));
  }

  Future<void> off() async {
    final payload = [
      CommandDefinition.setLighting.commandId,
      0x10,
      0x00,
      MachineEndpointConfig.minIntensity,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.lighting, payload: payload));
  }

  Future<void> fade(Duration duration) async {
    throw UnsupportedError('Fade is not supported by DiamondCam firmware');
  }

  Future<void> setIntensity(int intensity) async {
    final clamped = intensity.clamp(MachineEndpointConfig.minIntensity, MachineEndpointConfig.maxIntensity);
    _lastIntensity = clamped;
    final payload = <int>[
      CommandDefinition.setLighting.commandId,
      0x01,
      clamped,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.lighting, payload: payload));
  }
}
