import 'package:flutter_test/flutter_test.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import '../mocks/mock_device_transport.dart';

void main() {
  test('DeviceConnectionManager transitions on transport events', () async {
    final transport = MockDeviceTransport();
    final logger = const DeviceLogger();
    final manager = DeviceConnectionManager(transport: transport, logger: logger);

    final states = <DeviceConnectionState>[];
    final sub = manager.state.listen(states.add);

    await manager.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final device = DeviceInfo(id: 'mock-1', name: 'MockDevice', rssi: -50);
    await manager.connect(device);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(states, isNotEmpty);
    expect(manager.currentState.status, ConnectionStatus.connected);

    await manager.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await sub.cancel();
    manager.dispose();
  });

  test('reachable transport cannot become verified without updateVerifiedState', () async {
    final transport = MockDeviceTransport();
    final manager = DeviceConnectionManager(
      transport: transport,
      logger: const DeviceLogger(),
    );
    final device = DeviceInfo(id: 'mock-2', name: 'MockDevice', rssi: -40);
    await manager.connect(device);

    expect(manager.currentState.status, ConnectionStatus.connected);

    manager.updateVerifiedState(
      DeviceConnectionState.connectedUnverified(
        device.name,
        message: 'Invalid status payload',
      ),
    );
    expect(manager.currentState.status, isNot(ConnectionStatus.connected));

    manager.dispose();
  });
}
