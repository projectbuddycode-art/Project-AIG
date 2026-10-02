import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/models/reconnect_policy.dart';
import 'package:aig/features/esp32/services/http_transport.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/esp32/services/device_discovery_service.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:aig/features/esp32/services/heartbeat_service.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';

final machineHttpClientProvider = Provider<MachineHttpClient>((ref) {
  return MachineHttpClient();
});

final deviceLoggerProvider = Provider<DeviceLogger>((ref) {
  return const DeviceLogger();
});

final deviceTransportProvider = Provider<DeviceTransport>((ref) {
  return HttpTransport(
    logger: ref.read(deviceLoggerProvider),
    httpClient: ref.read(machineHttpClientProvider),
  );
});

final deviceProtocolProvider = Provider<DeviceProtocol>((ref) {
  return const DeviceProtocol();
});

final commandExecutorProvider = Provider<CommandExecutor>((ref) {
  return CommandExecutor(
    transport: ref.read(deviceTransportProvider),
    protocol: ref.read(deviceProtocolProvider),
    logger: ref.read(deviceLoggerProvider),
  );
});

final deviceConnectionStateProvider = StreamProvider<DeviceConnectionState>((
  ref,
) {
  return ref.watch(deviceConnectionManagerProvider).state;
});

final deviceDiscoveryServiceProvider = Provider<DeviceDiscoveryService>((ref) {
  return DeviceDiscoveryService(
    transport: ref.read(deviceTransportProvider),
    logger: ref.read(deviceLoggerProvider),
  );
});

final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  return HeartbeatService(logger: ref.read(deviceLoggerProvider));
});

final deviceConnectionManagerProvider = Provider<DeviceConnectionManager>((
  ref,
) {
  return DeviceConnectionManager(
    transport: ref.read(deviceTransportProvider),
    logger: ref.read(deviceLoggerProvider),
    reconnectPolicy: const ReconnectPolicy(maxRetries: 3),
  );
});

final discoveredDevicesProvider = StreamProvider.autoDispose<List<DeviceInfo>>((
  ref,
) {
  final discovery = ref.read(deviceDiscoveryServiceProvider);
  return discovery.devices;
});

final connectionStateProvider = StreamProvider((ref) {
  final manager = ref.read(deviceConnectionManagerProvider);
  return manager.state;
});
