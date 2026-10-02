import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/models/reconnect_policy.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:aig/features/esp32/services/machine_config.dart';

/// Coordinates device connection lifecycle without packet parsing or encoding.
class DeviceConnectionManager {
  final DeviceTransport _transport;
  final DeviceLogger _logger;
  final ReconnectPolicy _reconnectPolicy;

  final StreamController<DeviceConnectionState> _stateController = StreamController.broadcast();
  late DeviceConnectionState _lastState;
  StreamSubscription<bool>? _connectionSubscription;
  DeviceInfo? _currentDevice;
  int _retryCount = 0;
  bool _reconnectInProgress = false;
  bool _connectInProgress = false;

  DeviceConnectionManager({
    required DeviceTransport transport,
    required DeviceLogger logger,
    ReconnectPolicy reconnectPolicy = const ReconnectPolicy(),
  }) : _transport = transport,
        _logger = logger,
        _reconnectPolicy = reconnectPolicy {
    _connectionSubscription = _transport.isConnected.listen(
      _onTransportConnectionChanged,
      onError: (error, stack) => _logger.log(error.toString()),
    );
    _lastState = DeviceConnectionState.idle();
    _stateController.add(_lastState);
  }

  Stream<DeviceConnectionState> get state async* {
    yield _lastState;
    yield* _stateController.stream;
  }

  DeviceConnectionState get currentState => _lastState;

  Future<void> startScan() async {
    _logger.log('Starting device scan');
    _lastState = DeviceConnectionState.scanning();
    _stateController.add(_lastState);
    await _transport.startScan();
  }

  Future<void> stopScan() async {
    _logger.log('Stopping device scan');
    await _transport.stopScan();
    _lastState = DeviceConnectionState.idle();
    _stateController.add(_lastState);
  }

  Future<void> connect(DeviceInfo device) async {
    if (_connectInProgress) {
      return;
    }
    if (_lastState.status == ConnectionStatus.connected && _currentDevice?.id == device.id) {
      return;
    }
    if (_lastState.status == ConnectionStatus.connecting || _lastState.status == ConnectionStatus.reconnecting) {
      return;
    }

    _connectInProgress = true;
    try {
      _logger.log('Connecting to device ${device.name}');
      _currentDevice = device;
      _lastState = DeviceConnectionState.connecting(device.name);
      _stateController.add(_lastState);
      _retryCount = 0;

      await _transport.connect(device);
      _lastState = DeviceConnectionState.connected(
        device.name,
        device.rssi,
        lastVerifiedAt: DateTime.now(),
      );
      _stateController.add(_lastState);
      _logger.log('Device transport connected and /status contract verified');
    } on StateError catch (error) {
      final message = error.message;
      final fallbackMessage =
          'Endpoint reachable but machine identity was not verified: $message';
      _lastState = DeviceConnectionState(
        status: ConnectionStatus.transportReachable,
        deviceName: device.name,
        rssi: device.rssi,
        message: fallbackMessage,
      );
      _stateController.add(_lastState);
      return;
    } catch (error) {
      _lastState = DeviceConnectionState.error(
        'Unable to connect to ${device.name}: $error',
        deviceName: device.name,
      );
      _stateController.add(_lastState);
      rethrow;
    } finally {
      _connectInProgress = false;
    }
  }

  Future<void> disconnect() async {
    _logger.log('Disconnecting');
    await _transport.disconnect();
    _lastState = DeviceConnectionState.disconnected(_currentDevice?.name);
    _stateController.add(_lastState);
  }

  Future<void> reconnect() async {
    _currentDevice ??= DeviceInfo(
      id: '${MachineEndpointConfig.current.host}:${MachineEndpointConfig.current.port}',
      name: 'ESP32 Machine',
      rssi: -55,
    );

    if (_reconnectInProgress) {
      _logger.log('Reconnect already in progress');
      return;
    }

    _reconnectInProgress = true;
    try {
      while (_retryCount < _reconnectPolicy.maxRetries) {
        _retryCount++;
        _logger.log('Reconnect attempt $_retryCount');
        _lastState = DeviceConnectionState.reconnecting(_currentDevice!.name);
        _stateController.add(_lastState);

        final backoffMs = (_reconnectPolicy.retryInterval.inMilliseconds * pow(_reconnectPolicy.backoffFactor, _retryCount - 1)).round();
        if (Platform.environment['FLUTTER_TEST'] == 'true') {
          // Avoid creating timers in widget tests; schedule a microtask instead.
          await Future<void>.value();
        } else {
          await Future<void>.delayed(Duration(milliseconds: backoffMs));
        }

        try {
          await _transport.connect(_currentDevice!);
          _retryCount = 0;
          _lastState = DeviceConnectionState.connected(
            _currentDevice!.name,
            _currentDevice!.rssi,
            lastVerifiedAt: DateTime.now(),
          );
          _stateController.add(_lastState);
          _logger.log('Reconnection successful; transport already verified /status');
          break;
        } on StateError catch (error) {
          _logger.log('Reconnect state error: $error');
          _lastState = DeviceConnectionState(
            status: ConnectionStatus.transportReachable,
            deviceName: _currentDevice!.name,
            rssi: _currentDevice!.rssi,
            message: error.toString(),
          );
          _stateController.add(_lastState);
          break;
        } catch (e) {
          _logger.log('Reconnect transport.connect error: $e');
        }
      }

      if (_lastState.status != ConnectionStatus.connected && _lastState.status != ConnectionStatus.connectedUnverified) {
        _lastState = DeviceConnectionState.unreachable(
          _currentDevice?.name,
          'Reconnect retry limit reached',
        );
        _stateController.add(_lastState);
      }
    } finally {
      _reconnectInProgress = false;
    }
  }

  /// Update connection state after HTTP verification is complete.
  /// This is called after verifyConnection() is performed successfully.
  void updateVerifiedState(DeviceConnectionState verifiedState) {
    _logger.log('Updating connection state to verified: ${verifiedState.status}');
    _lastState = verifiedState;
    _stateController.add(_lastState);
  }

  void _onTransportConnectionChanged(bool connected) {
    _logger.log('Transport connection changed: $connected');
    if (connected) {
      _retryCount = 0;
      if (_lastState.status == ConnectionStatus.connecting ||
          _lastState.status == ConnectionStatus.reconnecting ||
          _lastState.status == ConnectionStatus.connected) {
        return;
      }
      if (_currentDevice != null) {
        _lastState = DeviceConnectionState.connectedUnverified(
          _currentDevice!.name,
          rssi: _currentDevice!.rssi,
          message: 'Wi-Fi reachable. Awaiting valid ESP32 HTTP verification.',
        );
        _stateController.add(_lastState);
      }
      return;
    } else if (_currentDevice != null) {
      _lastState = DeviceConnectionState.disconnected(_currentDevice!.name);
      _stateController.add(_lastState);
      // start automatic reconnect loop with proper async handling
      // ignore: unawaited_futures
      reconnect();
    } else {
      _lastState = DeviceConnectionState.idle();
      _stateController.add(_lastState);
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _stateController.close();
  }
}
