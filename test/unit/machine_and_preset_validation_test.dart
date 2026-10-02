import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/models/preset_model.dart';
import 'package:aig/features/esp32/models/rotation_config.dart';
import 'package:aig/features/esp32/models/lighting_config.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:aig/features/esp32/models/device_info.dart';

class _FakeTransport implements DeviceTransport {
  final StreamController<List<int>> _receive = StreamController.broadcast();
  final StreamController<bool> _connected = StreamController.broadcast();
  final StreamController<List<DeviceInfo>> _devices = StreamController.broadcast();

  @override
  Stream<List<int>> receive() => _receive.stream;

  @override
  Stream<bool> get isConnected => _connected.stream;

  @override
  Stream<List<DeviceInfo>> get discoveredDevices => _devices.stream;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(DeviceInfo device) async => _connected.add(true);

  @override
  Future<void> disconnect() async => _connected.add(false);

  @override
  Future<void> send(List<int> data) async => _receive.add([0x01]);

  @override
  Future<void> sendUrgent(List<int> data) => send(data);
}

void main() {
  test('MachineController verifies a live HTTP status response before reporting connection', () async {
    final transport = _FakeTransport();
    final executor = CommandExecutor(
      transport: transport,
      protocol: const DeviceProtocol(),
      logger: const DeviceLogger(),
      timeout: const Duration(milliseconds: 200),
    );
    final machine = MachineController(
      rotation: RotationController(executor),
      lighting: LightingController(executor),
      presets: PresetController(executor),
      status: MachineStatusController(executor),
      safety: SafetyController(executor, RotationController(executor)),
    );

    expect(() => machine.verifyConnection(), returnsNormally);
  });

  test('PresetController rejects an invalid preset before sending commands', () async {
    final transport = _FakeTransport();
    final executor = CommandExecutor(
      transport: transport,
      protocol: const DeviceProtocol(),
      logger: const DeviceLogger(),
      timeout: const Duration(milliseconds: 200),
    );
    final presetController = PresetController(executor);
    final invalidPreset = PresetModel(
      id: 'invalid',
      name: 'Invalid',
      rotation: const RotationConfig(speed: -5, clockwise: true, continuous: true),
      lighting: const LightingConfig(masterBrightness: -0.2, colorTemperature: 5000),
      captureDelay: const Duration(seconds: 2),
    );

    expect(() => presetController.executePreset(invalidPreset), throwsA(isA<StateError>()));
  });
}
