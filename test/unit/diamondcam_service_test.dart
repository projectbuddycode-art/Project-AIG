import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/esp32/models/machine_calibration.dart';
import 'package:aig/features/esp32/services/diamondcam_service.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';

void main() {
  tearDown(() {
    MachineEndpointConfig.current = MachineEndpointConfig.defaults();
  });

  test('calibration is unconfirmed until microsteps and CW direction are set', () {
    const cal = MachineCalibration.current;
    expect(cal.motorStepAngle, 1.8);
    expect(cal.gearRatio, 1.0);
    expect(cal.hasHomeSensor, isFalse);
    expect(cal.isCalibrationConfirmed, isFalse);
    expect(cal.calibrationStatus, 'Unconfirmed');
    expect(cal.stepsPerDegree, isNull);
    expect(cal.fullStepsPerRevolution, 200);
  });

  test('calibration computes steps/degree only when microsteps confirmed', () {
    const cal = MachineCalibration(microsteps: 8, positiveDirectionIsCW: true);
    expect(cal.isCalibrationConfirmed, isTrue);
    expect(cal.stepsPerRevolution, 1600);
    expect(cal.stepsPerDegree, closeTo(1600 / 360, 0.0001));
  });

  test('DiamondCamService rotate/continuous/stop/light payloads', () async {
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
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'success': true, 'message': 'ok'}));
      await request.response.close();
    });

    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final service = DiamondCamService(httpClient: MachineHttpClient());

    expect((await service.rotate(angle: 90, speed: 50)).ok, isTrue);
    expect((await service.continuous(direction: 'cw', speed: 30)).ok, isTrue);
    expect((await service.continuous(direction: 'ccw', speed: 30)).ok, isTrue);
    expect((await service.stop()).ok, isTrue);
    expect((await service.setLight(state: true, intensity: 80)).ok, isTrue);
    expect((await service.home()).ok, isFalse);
    expect((await service.home()).message, contains('Home sensor'));

    expect(seen[0]['path'], '/rotate');
    expect(seen[0]['body'], {'angle': 90, 'speed': 50});
    expect(seen[1]['body'], {'direction': 'cw', 'speed': 30});
    expect(seen[2]['body'], {'direction': 'ccw', 'speed': 30});
    expect(seen[3]['path'], '/rotate/stop');
    expect(seen[4]['body'], {'state': true, 'intensity': 80});
    expect(seen.length, 5);
  });

  test('getStatus distinguishes verified vs protocol mismatch', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    var call = 0;
    server.listen((request) async {
      call++;
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      if (call == 1) {
        request.response.write(jsonEncode({
          'connected': true,
          'rotation': 12,
          'light': true,
          'intensity': 40,
          'motorRunning': false,
        }));
      } else {
        request.response.write('{"status":"idle"}');
      }
      await request.response.close();
    });
    MachineEndpointConfig.current.apply(host: server.address.address, port: server.port);
    final service = DiamondCamService(httpClient: MachineHttpClient());
    final ok = await service.getStatus();
    expect(ok.ok, isTrue);
    final bad = await service.getStatus();
    expect(bad.ok, isFalse);
    expect(bad.message, contains('Protocol unverified'));
  });
}
