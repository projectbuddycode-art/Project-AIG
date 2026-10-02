import 'package:aig/features/esp32/models/preset_model.dart';
import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/models/command_definition.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';

/// Preset engine — only emits commands supported by DiamondCam firmware.
class PresetController {
  final CommandExecutor _executor;

  PresetController(this._executor);

  Future<void> executePreset(PresetModel preset) async {
    _validatePreset(preset);

    final rot = preset.rotation;
    final rotPayload = <int>[
      CommandDefinition.rotate.commandId,
      rot.clockwise ? 1 : 0,
      rot.continuous ? 1 : 0,
      (rot.speed * 100).clamp(0, 65535).round() & 0xFF,
      ((rot.speed * 100).clamp(0, 65535).round() >> 8) & 0xFF,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.rotation, payload: rotPayload));

    final intensity = (preset.lighting.masterBrightness.clamp(0.0, 1.0) * MachineEndpointConfig.maxIntensity)
        .round();
    final lightPayload = <int>[
      CommandDefinition.setLighting.commandId,
      0x01,
      intensity,
    ];
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.lighting, payload: lightPayload));

    if (preset.captureDelay > Duration.zero) {
      await Future<void>.delayed(preset.captureDelay);
    }
  }

  void _validatePreset(PresetModel preset) {
    if (preset.id.trim().isEmpty) {
      throw StateError('Preset id is required');
    }
    if (preset.name.trim().isEmpty) {
      throw StateError('Preset name is required');
    }
    if (preset.rotation.speed < 0 || preset.rotation.speed > 10) {
      throw StateError('Preset rotation speed must be between 0 and 10');
    }
    if (preset.lighting.masterBrightness < 0.0 || preset.lighting.masterBrightness > 1.0) {
      throw StateError('Preset brightness must be between 0.0 and 1.0');
    }
    if (preset.captureDelay < Duration.zero) {
      throw StateError('Preset capture delay cannot be negative');
    }
  }
}
