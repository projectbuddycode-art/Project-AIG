import 'dart:async';

import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE implementation of the generic device transport interface.
class BleTransport implements DeviceTransport {
  final FlutterReactiveBle _ble;
  final DeviceLogger _logger;
  final Uuid _serviceUuid;
  final Uuid _writeCharacteristicUuid;
  final Uuid _notifyCharacteristicUuid;

  final StreamController<List<DeviceInfo>> _deviceController = StreamController.broadcast();
  final StreamController<List<int>> _receiveController = StreamController.broadcast();

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  late QualifiedCharacteristic _writeCharacteristic;
  late QualifiedCharacteristic _notifyCharacteristic;
  late DeviceInfo _connectedDevice;

  final StreamController<bool> _connectionStateController = StreamController.broadcast();

  BleTransport({
    required FlutterReactiveBle ble,
    required DeviceLogger logger,
    required Uuid serviceUuid,
    required Uuid writeCharacteristicUuid,
    required Uuid notifyCharacteristicUuid,
  })  : _ble = ble,
        _logger = logger,
        _serviceUuid = serviceUuid,
        _writeCharacteristicUuid = writeCharacteristicUuid,
        _notifyCharacteristicUuid = notifyCharacteristicUuid;

  @override
  Stream<List<DeviceInfo>> get discoveredDevices => _deviceController.stream;

  @override
  Stream<bool> get isConnected => _connectionStateController.stream;

  @override
  Stream<List<int>> receive() => _receiveController.stream;

  @override
  Future<void> startScan() async {
    await stopScan();
    _scanSubscription = _ble.scanForDevices(
      withServices: [_serviceUuid],
      scanMode: ScanMode.balanced,
    ).listen(_onDeviceDiscovered, onError: _logger.log);
  }

  @override
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  Future<void> connect(DeviceInfo device) async {
    _connectedDevice = device;
    _connectionStateController.add(true);
    final connectionStream = _ble.connectToDevice(
      id: device.id,
      servicesWithCharacteristicsToDiscover: {
        _serviceUuid: [_writeCharacteristicUuid, _notifyCharacteristicUuid]
      },
      connectionTimeout: const Duration(seconds: 10),
    );

    await _connectionSubscription?.cancel();
    _connectionSubscription = connectionStream.listen(
      _onConnectionUpdate,
      onError: (Object error) {
        _logger.log('Connection error: $error');
        _connectionStateController.add(false);
      },
    );
  }

  @override
  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _connectionStateController.add(false);
  }

  @override
  Future<void> send(List<int> data) async {
    _logger.log('Sending ${data.length} bytes');
    await _ble.writeCharacteristicWithResponse(_writeCharacteristic, value: data);
  }

  @override
  Future<void> sendUrgent(List<int> data) => send(data);

  void _onDeviceDiscovered(DiscoveredDevice device) {
    final info = DeviceInfo(
      id: device.id,
      name: device.name.isNotEmpty ? device.name : device.id,
      rssi: device.rssi,
    );
    _deviceController.add([info]);
  }

  void _onConnectionUpdate(ConnectionStateUpdate update) async {
    _logger.log('Connection state: ${update.connectionState}');
    if (update.connectionState == DeviceConnectionState.connected) {
      _connectionStateController.add(true);
      _writeCharacteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _writeCharacteristicUuid,
        deviceId: _connectedDevice.id,
      );
      _notifyCharacteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _notifyCharacteristicUuid,
        deviceId: _connectedDevice.id,
      );
      await _notificationSubscription?.cancel();
      _notificationSubscription = _ble.subscribeToCharacteristic(_notifyCharacteristic).listen(
        _receiveController.add,
        onError: _logger.log,
      );
    } else if (update.connectionState == DeviceConnectionState.disconnected) {
      _connectionStateController.add(false);
    }
  }
}
