import 'dart:async';

import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_transport.dart';

/// Manages device discovery, filtering, and device list stream updates.
class DeviceDiscoveryService {
  final DeviceTransport _transport;
  final DeviceLogger _logger;

  final StreamController<List<DeviceInfo>> _devicesController = StreamController.broadcast();
  final Map<String, DeviceInfo> _discovered = {};

  DeviceDiscoveryService({required DeviceTransport transport, required DeviceLogger logger})
      : _transport = transport,
        _logger = logger {
    _transport.discoveredDevices.listen(
      _onDevicesDiscovered,
      onError: (error, stackTrace) => _logger.log(error.toString()),
    );
  }

  Stream<List<DeviceInfo>> get devices => _devicesController.stream;

  Future<void> startScan() async {
    _discovered.clear();
    await _transport.startScan();
  }

  Future<void> stopScan() async {
    await _transport.stopScan();
  }

  void _onDevicesDiscovered(List<DeviceInfo> devices) {
    for (final device in devices) {
      _discovered[device.id] = device;
    }
    final sortedDevices = _discovered.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    _devicesController.add(sortedDevices);
  }
}
