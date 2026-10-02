import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import '../mocks/mock_device_transport.dart';

/// Constructs a MachineController wired to a fake CommandExecutor that uses
/// the provided [MockDeviceTransport]. This lets tests exercise the real
/// controller logic without hardware.
MachineController makeFakeMachineController(MockDeviceTransport transport) {
  final protocol = const DeviceProtocol();
  final logger = const DeviceLogger();
  final executor = CommandExecutor(
    transport: transport,
    protocol: protocol,
    logger: logger,
    timeout: const Duration(milliseconds: 200),
  );

  final rotation = RotationController(executor);
  final lighting = LightingController(executor);
  final presets = PresetController(executor);
  final status = MachineStatusController(executor);
  final safety = SafetyController(executor, rotation);

  return MachineController(
    rotation: rotation,
    lighting: lighting,
    presets: presets,
    status: status,
    safety: safety,
  );
}
