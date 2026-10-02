import 'dart:async';

import 'package:aig/features/esp32/models/device_info.dart';

/// Abstracts a hardware transport for device communication.
abstract class DeviceTransport {
  Stream<List<DeviceInfo>> get discoveredDevices;

  Stream<bool> get isConnected;

  Future<void> startScan();

  Future<void> stopScan();

  Future<void> connect(DeviceInfo device);

  Future<void> disconnect();

  Future<void> send(List<int> data);

  /// High-priority send used by STOP. Default implementations use [send].
  Future<void> sendUrgent(List<int> data) => send(data);

  Stream<List<int>> receive();
}
