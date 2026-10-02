import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:aig/features/esp32/services/machine_command_mapper.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';

class HttpTransport implements DeviceTransport {
  HttpTransport({
    required DeviceLogger logger,
    MachineHttpClient? httpClient,
    MachineCommandMapper? mapper,
  })  : _logger = logger,
        _http = httpClient ?? MachineHttpClient(),
        _mapper = mapper ?? MachineCommandMapper() {
    _connectionStateController.add(_connected);
  }

  final DeviceLogger _logger;
  final MachineHttpClient _http;
  final MachineCommandMapper _mapper;

  final StreamController<List<DeviceInfo>> _deviceController = StreamController.broadcast();
  final StreamController<List<int>> _receiveController = StreamController.broadcast();
  final StreamController<bool> _connectionStateController = StreamController.broadcast();
  final Queue<_QueuedHttpWork> _requestQueue = Queue();

  bool _connected = false;
  bool _processingQueue = false;

  MachineHttpClient get httpClient => _http;

  @override
  Stream<List<DeviceInfo>> get discoveredDevices => _deviceController.stream;

  @override
  Stream<bool> get isConnected => _connectionStateController.stream;

  @override
  Stream<List<int>> receive() => _receiveController.stream;

  @override
  Future<void> startScan() async {
    final endpointId =
        '${MachineEndpointConfig.current.host}:${MachineEndpointConfig.current.port}';
    try {
      final response = await _http.get(MachineEndpointConfig.statusPath);
      _logger.log('HTTP scan ${response.uri} status=${response.statusCode}');
      if (response.statusCode != HttpStatus.ok) {
        _deviceController.add(const []);
        return;
      }
      final parsed = _http.parser.parse(response.body);
      if (!parsed.accepted) {
        _logger.log(
          'HTTP scan reached ${MachineEndpointConfig.current.originForLog} but status payload was not a supported machine response: ${parsed.identityReason}',
        );
        _deviceController.add(const []);
        return;
      }
      _deviceController.add([
        DeviceInfo(
          id: endpointId,
          name: 'ESP32 Machine',
          rssi: 0,
        ),
      ]);
    } catch (error) {
      _logger.log(
        'HTTP scan did not detect a live machine at ${MachineEndpointConfig.current.originForLog}: $error',
      );
      _deviceController.add(const []);
    }
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(DeviceInfo device) async {
    _logger.log('HTTP transport connecting to ${MachineEndpointConfig.current.originForLog}');
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _enqueue(urgent: false, () async {
          final response = await _http.get(MachineEndpointConfig.statusPath);
          if (response.statusCode != HttpStatus.ok) {
            throw HttpException('Machine returned HTTP ${response.statusCode}');
          }
          final parsed = _http.parser.parse(response.body);
          _receiveController.add([0x05, ...utf8.encode(response.body)]);
          if (!parsed.accepted) {
            _connected = false;
            _connectionStateController.add(false);
            throw StateError(
              'Unverified machine response: endpoint was reachable but payload did not match the expected machine status contract. ${parsed.identityReason}',
            );
          }
          _connected = true;
          _connectionStateController.add(true);
        });
        return;
      } catch (error) {
        lastError = error;
        if (error is StateError) {
          rethrow;
        }
        _logger.log('HTTP status check attempt $attempt failed: $error');
        await Future<void>.delayed(Duration(milliseconds: backoffMs(attempt)));
      }
    }
    _connected = false;
    _connectionStateController.add(false);
    throw SocketException('Machine did not respond to /status: $lastError');
  }

  @override
  Future<void> disconnect() async {
    _logger.log('HTTP transport disconnecting');
    _connected = false;
    _connectionStateController.add(false);
  }

  @override
  Future<void> send(List<int> data) => _sendMapped(data, forceUrgent: false);

  @override
  Future<void> sendUrgent(List<int> data) => _sendMapped(data, forceUrgent: true);

  Future<void> _sendMapped(List<int> data, {required bool forceUrgent}) async {
    if (data.isEmpty) {
      return;
    }
    final mapped = _mapper.map(data);
    if (mapped == null) {
      _receiveController.add([0xFF]);
      return;
    }
    await _enqueue(urgent: forceUrgent || mapped.urgent, () async {
      try {
        final response = mapped.method == 'GET'
            ? await _http.get(mapped.path)
            : await _http.post(mapped.path, mapped.body);
        if (mapped.method == 'GET') {
          if (response.statusCode == HttpStatus.ok) {
            _receiveController.add([0x05, ...utf8.encode(response.body)]);
              _connected = true;
              _connectionStateController.add(true);
            } else {
              _receiveController.add([0xFF]);
            }
          return;
        }
        _receiveController.add(response.accepted ? [0x01] : [0xFF]);
      } catch (error) {
        _logger.log('HTTP send failed: $error');
        _receiveController.add([0xFF]);
      }
    });
  }

  Future<void> _enqueue(Future<void> Function() work, {required bool urgent}) {
    final queued = _QueuedHttpWork(work);
    if (urgent) {
      _requestQueue.addFirst(queued);
    } else {
      _requestQueue.add(queued);
    }
    _pump();
    return queued.completer.future;
  }

  void _pump() {
    if (_processingQueue) {
      return;
    }
      _processingQueue = true;
    scheduleMicrotask(() async {
      while (_requestQueue.isNotEmpty) {
        final task = _requestQueue.removeFirst();
        try {
          await task.work();
          if (!task.completer.isCompleted) {
            task.completer.complete();
          }
        } catch (error, stack) {
          if (!task.completer.isCompleted) {
            task.completer.completeError(error, stack);
          }
        }
      }
      _processingQueue = false;
      if (_requestQueue.isNotEmpty) {
        _pump();
      }
    });
  }
}

class _QueuedHttpWork {
  _QueuedHttpWork(this.work);

  final Future<void> Function() work;
  final Completer<void> completer = Completer<void>();
}
