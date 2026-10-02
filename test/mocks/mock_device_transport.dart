import 'dart:async';

import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/services/device_transport.dart';

class MockDeviceTransport implements DeviceTransport {
  final _discovered = StreamController<List<DeviceInfo>>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  final _recv = StreamController<List<int>>.broadcast();

  @override
  Stream<bool> get isConnected => _connected.stream;

  @override
  Stream<List<DeviceInfo>> get discoveredDevices => _discovered.stream;

  @override
  Future<void> connect(DeviceInfo device) async {
    _connected.add(true);
  }

  @override
  Future<void> disconnect() async {
    _connected.add(false);
  }

  @override
  Future<void> startScan() async {
    // emit a fake device
    _discovered.add([DeviceInfo(id: 'mock-1', name: 'MockDevice', rssi: -50)]);
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> send(List<int> data) async {
    // simulate device acknowledgement after a small delay
    Future<void>.delayed(Duration(milliseconds: 30), () {
      // simple ack header 0x01
      _recv.add([0x01]);
    });
  }

  @override
  Future<void> sendUrgent(List<int> data) => send(data);

  @override
  Stream<List<int>> receive() => _recv.stream;
}

