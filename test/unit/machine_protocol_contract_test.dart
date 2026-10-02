import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/models/device_info.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_transport.dart';
import 'package:aig/features/esp32/services/machine_command_mapper.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';
import 'package:aig/features/esp32/services/machine_status_parser.dart';

Map<String, dynamic> diamondCamStatus({
  bool connected = true,
  num rotation = 0,
  dynamic light = false,
  num intensity = 0,
  bool motorRunning = false,
}) =>
    {
      'connected': connected,
      'rotation': rotation,
      'light': light,
      'intensity': intensity,
      'motorRunning': motorRunning,
    };

void main() {
  tearDown(() {
    MachineEndpointConfig.current = MachineEndpointConfig.defaults();
  });

  test('default endpoint is http://192.168.4.1:80', () {
    final cfg = MachineEndpointConfig.defaults();
    expect(cfg.host, '192.168.4.1');
    expect(cfg.port, 80);
    expect(cfg.originForLog, 'http://192.168.4.1:80');
    expect(cfg.uriFor('/status').host, '192.168.4.1');
    expect(cfg.uriFor('/status').port, 80);
    expect(cfg.uriFor('/status').path, '/status');
    expect(cfg.describe(cfg.uriFor('/status')), 'http://192.168.4.1:80/status');
  });

  test('status parser accepts exact DiamondCam /status contract', () {
    final parsed = MachineStatusParser().parse(jsonEncode(diamondCamStatus(
      rotation: 45,
      light: true,
      intensity: 80,
      motorRunning: true,
    )));
    expect(parsed.accepted, isTrue);
    expect(parsed.firmwareVersion, isNull);
    expect(parsed.rotation, 45);
    expect(parsed.intensity, 80);
    expect(parsed.motorRunning, isTrue);
  });

  test('status parser rejects incomplete or invented payloads', () {
    expect(MachineStatusParser().parse('{"status":"idle","version":"1.2.3"}').accepted, isFalse);
    expect(MachineStatusParser().parse('{"weather":"sunny"}').accepted, isFalse);
    expect(MachineStatusParser().parse('{"connected":true}').accepted, isFalse);
  });

  test('rotate maps to POST /rotate {angle,speed} only', () {
    // [header 0x02, commandId, 0x10, angleLo, angleHi, speedLo, speedHi]
    final mapped = MachineCommandMapper().map([0x02, 0x02, 0x10, 90, 0, 500 & 0xFF, (500 >> 8) & 0xFF]);
    expect(mapped!.method, 'POST');
    expect(mapped.path, '/rotate');
    expect(mapped.body.keys.toSet(), {'angle', 'speed'});
    expect(mapped.body['angle'], 90);
    expect(mapped.body['speed'], 5.0);
  });

  test('continuous maps to POST /rotate/continuous {direction,speed}', () {
    final mapped = MachineCommandMapper().map([0x02, 0x02, 1, 1, 300 & 0xFF, (300 >> 8) & 0xFF]);
    expect(mapped!.path, '/rotate/continuous');
    expect(mapped.body.keys.toSet(), {'direction', 'speed'});
    expect(mapped.body['direction'], 'cw');
    expect(mapped.body['speed'], 3.0);
  });

  test('continuous CCW uses non-cw direction string', () {
    final mapped = MachineCommandMapper().map([0x02, 0x02, 0, 1, 200 & 0xFF, (200 >> 8) & 0xFF]);
    expect(mapped!.body['direction'], 'ccw');
  });

  test('stop maps to POST /rotate/stop with empty body and urgent', () {
    final mapped = MachineCommandMapper().map([0x02, 0x02, 0x00]);
    expect(mapped!.path, '/rotate/stop');
    expect(mapped.method, 'POST');
    expect(mapped.body, isEmpty);
    expect(mapped.urgent, isTrue);
  });

  test('light on/off maps to {state,intensity}', () {
    final on = MachineCommandMapper().map([0x03, 0x03, 0x10, 0x01, 75]);
    expect(on!.path, '/light');
    expect(on.body, {'state': true, 'intensity': 75});

    final off = MachineCommandMapper().map([0x03, 0x03, 0x10, 0x00, 0]);
    expect(off!.body, {'state': false, 'intensity': 0});
  });

  test('firmware GET is not mapped', () {
    expect(MachineCommandMapper().map([0x06]), isNull);
  });

  test('legacy HOME opcode 0x20 is not mapped to angle 0', () {
    expect(MachineCommandMapper().map([0x02, 0x02, 0x20, 0, 0]), isNull);
  });

  test('command success requires success:true', () {
    expect(MachineStatusParser().isCommandSuccess(200, '{"success":true,"message":"Rotating"}'), isTrue);
    expect(MachineStatusParser().isCommandSuccess(200, '{"success":false}'), isFalse);
    expect(MachineStatusParser().isCommandSuccess(200, 'ok'), isFalse);
    expect(MachineStatusParser().isCommandSuccess(500, '{"success":true}'), isFalse);
  });

  test('UI connection labels', () {
    expect(connectionStatusLabel(ConnectionStatus.connected), 'Protocol Verified');
    expect(connectionStatusLabel(ConnectionStatus.connectedUnverified), 'ESP32 Reachable · Protocol Unverified');
    expect(connectionStatusLabel(ConnectionStatus.unreachable), 'Unreachable');
    expect(connectionStatusLabel(ConnectionStatus.error), 'Error');
    expect(connectionStatusLabel(ConnectionStatus.disconnected), 'Disconnected');
  });

  test('verifyConnection requires DiamondCam status fields', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      if (request.uri.path == '/status') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(diamondCamStatus(rotation: 12, light: true, intensity: 40)));
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });

    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final state = await _machine().verifyConnection();
    expect(state.status, ConnectionStatus.connected);
    expect(state.firmwareVersion, isNull);
  });

  test('reachable but invalid status → Connected · Unverified', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response
        ..statusCode = 200
        ..write('{"status":"idle"}');
      await request.response.close();
    });
    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final state = await _machine().verifyConnection();
    expect(state.status, ConnectionStatus.connectedUnverified);
  });

  test('HTTP integration: exact methods, paths, and bodies', () async {
    final seen = <Map<String, dynamic>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      seen.add({
        'method': request.method,
        'path': request.uri.path,
        'body': body.isEmpty ? null : jsonDecode(body),
      });
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/status') {
        request.response.write(jsonEncode(diamondCamStatus()));
      } else {
        request.response.write(jsonEncode({'success': true, 'message': 'ok'}));
      }
      await request.response.close();
    });

    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final client = MachineHttpClient();

    await client.get('/status');
    await client.post('/rotate', {'angle': 90, 'speed': 5});
    await client.post('/rotate/continuous', {'direction': 'cw', 'speed': 3});
    await client.post('/rotate/stop', const {});
    await client.post('/light', {'state': true, 'intensity': 50});
    await client.post('/reset', const {});

    expect(seen[0], {'method': 'GET', 'path': '/status', 'body': null});
    expect(seen[1]['path'], '/rotate');
    expect(seen[1]['body'], {'angle': 90, 'speed': 5});
    expect(seen[2]['path'], '/rotate/continuous');
    expect(seen[2]['body'], {'direction': 'cw', 'speed': 3});
    expect(seen[3]['path'], '/rotate/stop');
    expect(seen[3]['body'], {});
    expect(seen[4]['body'], {'state': true, 'intensity': 50});
    expect(seen[5]['path'], '/reset');
  });

  test('diagnostics uses real endpoints only — no /firmware /preset /home', () async {
    final seen = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      seen.add('${request.method} ${request.uri.path}');
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/status') {
        request.response.write(jsonEncode(diamondCamStatus(rotation: 10)));
      } else {
        request.response.write(jsonEncode({'success': true, 'message': 'ok'}));
      }
      await request.response.close();
    });

    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final report = await _machine().runDiagnostics();
    expect(report['transport'], 'PASS');
    expect(report['identity'], 'PASS');
    expect(report['rotation'], 'PASS');
    expect(report['lighting'], 'PASS');
    expect(report['stop'], 'PASS');
    expect(report['firmware'], 'UNAVAILABLE');
    expect(report['pass'], isTrue);
    expect(seen, containsAll(['GET /status', 'POST /rotate', 'POST /light', 'POST /rotate/stop']));
    expect(seen.any((e) => e.contains('/firmware')), isFalse);
    expect(seen.any((e) => e.contains('/preset')), isFalse);
    expect(seen.any((e) => e.contains('/home')), isFalse);
  });

  test('timeout cannot show success', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      await Future<void>.delayed(const Duration(seconds: 8));
      await request.response.close();
    });
    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final client = MachineHttpClient(timeout: const Duration(milliseconds: 80));
    await expectLater(client.get('/status'), throwsA(isA<TimeoutException>()));
  });
}

MachineController _machine() {
  final transport = _RecordingTransport();
  final executor = CommandExecutor(
    transport: transport,
    protocol: const DeviceProtocol(),
    logger: const DeviceLogger(),
    timeout: const Duration(milliseconds: 200),
  );
  return MachineController(
    rotation: RotationController(executor),
    lighting: LightingController(executor),
    presets: PresetController(executor),
    status: MachineStatusController(executor),
    safety: SafetyController(executor, RotationController(executor)),
  );
}

class _RecordingTransport implements DeviceTransport {
  final _receive = StreamController<List<int>>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  final _devices = StreamController<List<DeviceInfo>>.broadcast();

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
  Future<void> sendUrgent(List<int> data) async => send(data);
}
