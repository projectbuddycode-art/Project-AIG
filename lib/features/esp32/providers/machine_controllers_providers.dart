import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/providers/device_connection_manager_provider.dart';
import 'package:aig/features/esp32/services/diamondcam_service.dart';

final rotationControllerProvider = Provider<RotationController>((ref) {
  final executor = ref.read(commandExecutorProvider);
  return RotationController(executor);
});

final lightingControllerProvider = Provider<LightingController>((ref) {
  final executor = ref.read(commandExecutorProvider);
  return LightingController(executor);
});

final presetControllerProvider = Provider<PresetController>((ref) {
  final executor = ref.read(commandExecutorProvider);
  return PresetController(executor);
});

final machineStatusControllerProvider = Provider<MachineStatusController>((
  ref,
) {
  final executor = ref.read(commandExecutorProvider);
  return MachineStatusController(executor);
});

final safetyControllerProvider = Provider<SafetyController>((ref) {
  final executor = ref.read(commandExecutorProvider);
  final rotation = ref.read(rotationControllerProvider);
  return SafetyController(executor, rotation);
});

final diamondCamServiceProvider = Provider<DiamondCamService>((ref) {
  return DiamondCamService(httpClient: ref.read(machineHttpClientProvider));
});

final machineControllerProvider = Provider<MachineController>((ref) {
  return MachineController(
    rotation: ref.read(rotationControllerProvider),
    lighting: ref.read(lightingControllerProvider),
    presets: ref.read(presetControllerProvider),
    status: ref.read(machineStatusControllerProvider),
    safety: ref.read(safetyControllerProvider),
  );
});
