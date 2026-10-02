import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/esp32/models/machine_calibration.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';
import 'package:aig/features/esp32/services/diamondcam_service.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';
import 'package:aig/features/esp32/services/machine_status_parser.dart';

void main() {
  final parser = MachineStatusParser();

  tearDown(() {
    MachineEndpointConfig.current = MachineEndpointConfig.defaults();
  });

  group('status validation', () {
    test('1 valid /status', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 12,
        'light': true,
        'intensity': 40,
        'motorRunning': true,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.connected, isTrue);
      expect(parsed.rotation, 12);
      expect(parsed.motorRunning, isTrue);
    });

    test('2 missing connected', () {
      expect(
        parser.parse('{"rotation":1,"light":true,"intensity":1,"motorRunning":false}').accepted,
        isFalse,
      );
    });

    test('3 missing rotation', () {
      expect(
        parser.parse('{"connected":true,"light":true,"intensity":1,"motorRunning":false}').identityReason,
        contains('rotation'),
      );
    });

    test('4 missing light', () {
      expect(
        parser.parse('{"connected":true,"rotation":1,"intensity":1,"motorRunning":false}').accepted,
        isFalse,
      );
    });

    test('5 missing intensity', () {
      expect(
        parser.parse('{"connected":true,"rotation":1,"light":true,"motorRunning":false}').accepted,
        isFalse,
      );
    });

    test('6 missing motorRunning', () {
      expect(
        parser.parse('{"connected":true,"rotation":1,"light":true,"intensity":1}').accepted,
        isFalse,
      );
    });

    test('7 connected=false is valid', () {
      final parsed = parser.parse(jsonEncode({
        'connected': false,
        'rotation': 1,
        'light': true,
        'intensity': 1,
        'motorRunning': true,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.connected, isFalse);
    });

    test('8 rotation=0 is valid', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 0,
        'light': true,
        'intensity': 1,
        'motorRunning': true,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.rotation, 0);
    });

    test('9 intensity=0 is valid', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 1,
        'light': true,
        'intensity': 0,
        'motorRunning': true,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.intensity, 0);
    });

    test('10 light=false is valid', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 1,
        'light': false,
        'intensity': 1,
        'motorRunning': true,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.light, isFalse);
    });

    test('11 motorRunning=false is valid', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 1,
        'light': true,
        'intensity': 1,
        'motorRunning': false,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.motorRunning, isFalse);
    });

    test('12 malformed JSON', () {
      final parsed = parser.parse('{not-json');
      expect(parsed.accepted, isFalse);
      expect(parsed.identityReason, contains('not valid JSON'));
    });

    test('wrapped data object is unwrapped without loosening required keys', () {
      final parsed = parser.parse(jsonEncode({
        'data': {
          'connected': true,
          'rotation': 9,
          'light': false,
          'intensity': 0,
          'motorRunning': false,
        }
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.rotation, 9);
    });

    test('double-encoded JSON is decoded', () {
      final inner = jsonEncode({
        'connected': true,
        'rotation': 3,
        'light': false,
        'intensity': 0,
        'motorRunning': false,
      });
      final parsed = parser.parse(jsonEncode(inner));
      expect(parsed.accepted, isTrue);
    });

    test('snake_case motor_running alias maps to motorRunning', () {
      final parsed = parser.parse(jsonEncode({
        'connected': true,
        'rotation': 0,
        'light': false,
        'intensity': 0,
        'motor_running': false,
      }));
      expect(parsed.accepted, isTrue);
      expect(parsed.motorRunning, isFalse);
    });
  });

  group('commands and info', () {
    test('13 HTTP 400', () {
      final parsed = parser.parseCommand(400, '{"success":false,"message":"bad"}');
      expect(parsed.accepted, isFalse);
      expect(parsed.stage, MachineCommandStage.httpError);
    });

    test('14 HTTP 500', () {
      final parsed = parser.parseCommand(500, '{"success":false}');
      expect(parsed.stage, MachineCommandStage.httpError);
    });

    test('15 /rotate success requires success=true', () {
      expect(parser.isCommandSuccess(200, '{"success":true,"message":"Rotating"}'), isTrue);
    });

    test('16 /rotate rejection', () {
      expect(parser.isCommandSuccess(200, '{"success":false,"message":"busy"}'), isFalse);
      expect(parser.parseCommand(200, '{"ok":true}').accepted, isFalse);
    });

    test('17 /continuous cw payload', () {
      expect(
        DiamondCamProtocol.continuousBody(direction: 'cw', speed: 30),
        {'direction': 'cw', 'speed': 30},
      );
    });

    test('18 /continuous ccw payload', () {
      expect(
        DiamondCamProtocol.continuousBody(direction: 'ccw', speed: 12),
        {'direction': 'ccw', 'speed': 12},
      );
      expect(DiamondCamProtocol.isContinuousDirection('CW'), isTrue);
      expect(DiamondCamProtocol.isContinuousDirection('left'), isFalse);
    });

    test('19 /light payload', () {
      expect(
        DiamondCamProtocol.lightBody(state: true, intensity: 80),
        {'state': true, 'intensity': 80},
      );
    });

    test('21 /info unknown calibration', () {
      final info = parser.parseInfo(jsonEncode({
        'machineId': 'AIG-DIAMONDCAM',
        'firmware': '2.0.0',
        'motor': {'stepAngle': 1.8},
        'mechanical': {'gearRatio': 1.0},
        'calibration': {'confirmed': false},
        'sensors': {'home': false, 'limit': false},
      }));
      expect(info, isNotNull);
      expect(info!.calibrationConfirmed, isFalse);
      expect(info.calibrationLabel, 'Unconfirmed');
      expect(info.microstepsLabel, 'Unconfirmed');
      expect(info.directionLabel, 'Unconfirmed');
      expect(info.hasHomeSensor, isFalse);
      expect(info.machineId, isNot('192.168.4.1'));
    });

    test('23 /info confirmed calibration', () {
      final info = parser.parseInfo(jsonEncode({
        'machineId': 'AIG-DIAMONDCAM',
        'firmware': '2.0.0',
        'motor': {'stepAngle': 1.8},
        'mechanical': {'gearRatio': 1.0},
        'calibration': {
          'microsteps': 8,
          'stepsPerRevolution': 1600,
          'stepsPerDegree': 1600 / 360,
          'positiveDirectionIsCW': true,
          'confirmed': true,
        },
        'sensors': {'home': false, 'limit': false},
      }));
      expect(info!.calibrationConfirmed, isTrue);
      expect(info.microsteps, 8);
      expect(info.positiveDirectionIsCW, isTrue);
    });
  });

  test('GET /info keeps calibration unconfirmed while reporting 3200 pulse geometry', () {
    final info = parser.parseInfo(jsonEncode({
      'machineId': 'AIG-DIAMONDCAM',
      'firmware': '2.2.0',
      'motor': {'type': 'NEMA17', 'stepAngle': 1.8, 'fullStepsPerRevolution': 200},
      'mechanical': {'drive': 'direct', 'gearRatio': 1.0},
      'calibration': {
        'microsteps': 16,
        'pulsesPerRevolution': 3200,
        'pulsesPerDegree': 3200 / 360,
        'confirmed': false,
      },
      'sensors': {'home': false, 'limit': false, 'encoder': false},
    }));
    expect(info, isNotNull);
    expect(info!.calibrationConfirmed, isFalse);
    expect(info.microsteps, 16);
    expect(info.pulsesPerRevolution, 3200);
    expect(info.pulsesPerDegree, closeTo(3200 / 360, 0.0001));
    expect(info.positiveDirectionIsCW, isNull);
  });

  test('22 local calibration remains unconfirmed without microsteps', () {
    const cal = MachineCalibration.current;
    expect(cal.isCalibrationConfirmed, isFalse);
    expect(cal.stepsPerDegree, isNull);
  });

  test('HTTP integration rotate/continuous/stop/light/reset/health/info/status', () async {
    final seen = <Map<String, dynamic>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      seen.add({
        'method': request.method,
        'path': request.uri.path,
        'contentType': request.headers.contentType?.mimeType,
        'accept': request.headers.value(HttpHeaders.acceptHeader),
        'contentLength': request.contentLength,
        'transferEncoding': request.headers.value(HttpHeaders.transferEncodingHeader),
        'rawBody': body,
        'body': body.isEmpty ? null : jsonDecode(body),
      });
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/status') {
        request.response.write(jsonEncode({
          'connected': true,
          'rotation': 0,
          'light': false,
          'intensity': 0,
          'motorRunning': false,
        }));
      } else if (request.uri.path == '/health') {
        request.response.write(jsonEncode({'ok': true, 'healthy': true}));
      } else if (request.uri.path == '/info') {
        request.response.write(jsonEncode({
          'machineId': 'AIG-DIAMONDCAM',
          'firmware': '2.0.0',
          'calibration': {'confirmed': false},
          'sensors': {'home': false, 'limit': false},
        }));
      } else {
        request.response.write(jsonEncode({'success': true, 'message': 'ok'}));
      }
      await request.response.close();
    });

    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final service = DiamondCamService(httpClient: MachineHttpClient());

    expect((await service.getHealth()).ok, isTrue);
    expect((await service.info()).ok, isTrue);
    expect((await service.getStatus()).ok, isTrue);
    expect((await service.rotate(angle: 90, speed: 50)).ok, isTrue);
    expect((await service.continuous(direction: 'cw', speed: 30)).ok, isTrue);
    expect((await service.continuous(direction: 'ccw', speed: 30)).ok, isTrue);
    expect((await service.stop()).ok, isTrue);
    expect((await service.setLight(state: true, intensity: 80)).ok, isTrue);
    expect((await service.reset()).ok, isTrue);
    expect((await service.home()).ok, isFalse);

    expect(seen.map((e) => '${e['method']} ${e['path']}'), containsAll([
      'GET /health',
      'GET /info',
      'GET /status',
      'POST /rotate',
      'POST /rotate/continuous',
      'POST /rotate/stop',
      'POST /light',
      'POST /reset',
    ]));
    expect(seen.firstWhere((e) => e['path'] == '/rotate')['body'], {'angle': 90, 'speed': 50});
    expect(seen.firstWhere((e) => e['path'] == '/rotate')['rawBody'], '{"angle":90,"speed":50}');
    expect(seen.where((e) => e['path'] == '/rotate/continuous').map((e) => e['body']['direction']), ['cw', 'ccw']);
    final continuous = seen.where((e) => e['path'] == '/rotate/continuous').toList();
    expect(continuous[0]['rawBody'], '{"direction":"cw","speed":30}');
    expect(continuous[1]['rawBody'], '{"direction":"ccw","speed":30}');
    expect(continuous[0]['contentType'], 'application/json');
    expect(continuous[0]['accept'], 'application/json');
    expect(continuous[0]['transferEncoding'], isNot(contains('chunked')));
    expect(continuous[0]['contentLength'], '{"direction":"cw","speed":30}'.length);
    expect(seen.firstWhere((e) => e['path'] == '/rotate/stop')['body'], {});
    expect(seen.firstWhere((e) => e['path'] == '/rotate/stop')['rawBody'], '{}');
    expect(seen.firstWhere((e) => e['path'] == '/light')['rawBody'], '{"state":true,"intensity":80}');
    expect(seen.firstWhere((e) => e['path'] == '/reset')['rawBody'], '{}');
    for (final entry in seen.where((e) => e['method'] == 'POST')) {
      expect(entry['rawBody'], isNot(startsWith('"')));
      expect(entry['contentType'], 'application/json');
    }
  });

  test('90 degree and 180 degree pulse math uses 3200 pulses per revolution', () {
    expect(DiamondCamProtocol.fullStepsPerRevolution, 200);
    expect(DiamondCamProtocol.microsteps, 16);
    expect(DiamondCamProtocol.pulsesPerRevolution, 3200);
    expect((90 * DiamondCamProtocol.pulsesPerDegree).round(), 800);
    expect((180 * DiamondCamProtocol.pulsesPerDegree).round(), 1600);
    expect(DiamondCamProtocol.pulsesPerRevolution, isNot(400));
  });

  test('success false is rejected and invalid JSON is not accepted', () {
    final rejected = parser.parseCommand(200, '{"success":false,"error":"busy"}');
    expect(rejected.accepted, isFalse);
    expect(rejected.stage, MachineCommandStage.rejected);
    final invalid = parser.parseCommand(200, '{not-json');
    expect(invalid.accepted, isFalse);
    expect(invalid.stage, MachineCommandStage.invalidJson);
    final missing = parser.parseCommand(400, '{"success":false,"error":"direction and speed are required"}');
    expect(missing.accepted, isFalse);
    expect(missing.stage, MachineCommandStage.httpError);
  });

  test('20 HTTP 400 rotate surfaces machine body', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': false, 'message': 'angle required'}));
      await request.response.close();
    });
    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final result = await DiamondCamService(httpClient: MachineHttpClient()).rotate(angle: 90, speed: 10);
    expect(result.ok, isFalse);
    expect(result.stage, MachineCommandStage.httpError);
    expect(result.message, contains('400'));
  });

  test('24 machine unreachable', () async {
    MachineEndpointConfig.current.apply(host: '127.0.0.1', port: 1);
    final result = await DiamondCamService(
      httpClient: MachineHttpClient(timeout: const Duration(milliseconds: 200)),
    ).getStatus();
    expect(result.ok, isFalse);
    expect(result.stage, MachineCommandStage.transportFailure);
  });
}
