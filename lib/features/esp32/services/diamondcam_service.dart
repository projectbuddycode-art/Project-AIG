import 'dart:async';
import 'dart:io';

import 'package:aig/features/esp32/models/machine_calibration.dart';
import 'package:aig/features/esp32/models/machine_info.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';
import 'package:aig/features/esp32/services/machine_status_parser.dart';

class DiamondCamResult {
  const DiamondCamResult({
    required this.ok,
    required this.message,
    this.statusCode,
    this.body,
    this.status,
    this.info,
    this.healthOk = false,
    this.commandAccepted = false,
    this.physicalVerified = false,
    this.stage = MachineCommandStage.notSent,
  });

  final bool ok;
  final String message;
  final int? statusCode;
  final String? body;
  final MachineStatusParseResult? status;
  final MachineInfo? info;
  final bool healthOk;
  final bool commandAccepted;
  final bool physicalVerified;
  final MachineCommandStage stage;

  factory DiamondCamResult.failure(
    String message, {
    int? statusCode,
    String? body,
    MachineCommandStage stage = MachineCommandStage.notSent,
    MachineStatusParseResult? status,
  }) {
    return DiamondCamResult(
      ok: false,
      message: message,
      statusCode: statusCode,
      body: body,
      stage: stage,
      status: status,
    );
  }
}

/// Direct HTTP client for the DiamondCam firmware contract.
class DiamondCamService {
  DiamondCamService({
    MachineHttpClient? httpClient,
    this.calibration = MachineCalibration.current,
  }) : _http = httpClient ?? MachineHttpClient();

  final MachineHttpClient _http;
  final MachineCalibration calibration;

  Future<DiamondCamResult> getHealth() async {
    try {
      final response = await _http.get(MachineEndpointConfig.healthPath);
      final ok = _http.parser.parseHealthOk(response.statusCode, response.body);
      if (!ok) {
        return DiamondCamResult.failure(
          'GET /health failed HTTP ${response.statusCode}. Body: ${response.body}',
          statusCode: response.statusCode,
          body: response.body,
          stage: MachineCommandStage.httpError,
        );
      }
      return DiamondCamResult(
        ok: true,
        message: 'GET /health ok',
        statusCode: response.statusCode,
        body: response.body,
        healthOk: true,
        commandAccepted: true,
        stage: MachineCommandStage.accepted,
      );
    } on TimeoutException {
      return DiamondCamResult.failure(
        'GET /health timed out',
        stage: MachineCommandStage.transportFailure,
      );
    } on SocketException {
      return DiamondCamResult.failure(
        'ESP32 unreachable. Join ${DiamondCamProtocol.wifiSsid} Wi-Fi.',
        stage: MachineCommandStage.transportFailure,
      );
    } catch (error) {
      return DiamondCamResult.failure(
        'GET /health failed: $error',
        stage: MachineCommandStage.transportFailure,
      );
    }
  }

  Future<DiamondCamResult> getStatus() async {
    try {
      final response = await _http.get(MachineEndpointConfig.statusPath);
      if (response.statusCode != HttpStatus.ok) {
        return DiamondCamResult.failure(
          'ESP32 returned HTTP ${response.statusCode} for GET /status. Body: ${response.body}',
          statusCode: response.statusCode,
          body: response.body,
          stage: MachineCommandStage.httpError,
        );
      }
      final parsed = _http.parser.parse(response.body);
      if (!parsed.accepted) {
        return DiamondCamResult(
          ok: false,
          message: 'ESP32 reachable. Protocol unverified. ${parsed.identityReason}',
          statusCode: response.statusCode,
          body: response.body,
          status: parsed,
          stage: MachineCommandStage.rejected,
        );
      }
      return DiamondCamResult(
        ok: true,
        message: 'ESP32 connected. Protocol verified. Commanded angle is not a measured position.',
        statusCode: response.statusCode,
        body: response.body,
        status: parsed,
        commandAccepted: true,
        stage: MachineCommandStage.accepted,
      );
    } on TimeoutException {
      return DiamondCamResult.failure(
        'Machine did not respond in time',
        stage: MachineCommandStage.transportFailure,
      );
    } on SocketException {
      return DiamondCamResult.failure(
        'ESP32 unreachable. Join ${DiamondCamProtocol.wifiSsid} Wi-Fi.',
        stage: MachineCommandStage.transportFailure,
      );
    } catch (error) {
      return DiamondCamResult.failure(
        'Unable to read machine status: $error',
        stage: MachineCommandStage.transportFailure,
      );
    }
  }

  Future<DiamondCamResult> info() async {
    try {
      final response = await _http.get(MachineEndpointConfig.infoPath);
      if (response.statusCode == HttpStatus.notFound) {
        return DiamondCamResult.failure(
          'GET /info is not available on this firmware',
          statusCode: response.statusCode,
          body: response.body,
          stage: MachineCommandStage.httpError,
        );
      }
      if (response.statusCode != HttpStatus.ok) {
        return DiamondCamResult.failure(
          'GET /info HTTP ${response.statusCode}. Body: ${response.body}',
          statusCode: response.statusCode,
          body: response.body,
          stage: MachineCommandStage.httpError,
        );
      }
      final parsed = _http.parser.parseInfo(response.body);
      if (parsed == null) {
        return DiamondCamResult.failure(
          'GET /info returned invalid JSON. Body: ${response.body}',
          statusCode: response.statusCode,
          body: response.body,
          stage: MachineCommandStage.invalidJson,
        );
      }
      return DiamondCamResult(
        ok: true,
        message: 'GET /info received',
        statusCode: response.statusCode,
        body: response.body,
        info: parsed,
        commandAccepted: true,
        stage: MachineCommandStage.accepted,
      );
    } on TimeoutException {
      return DiamondCamResult.failure(
        'GET /info timed out',
        stage: MachineCommandStage.transportFailure,
      );
    } on SocketException {
      return DiamondCamResult.failure(
        'ESP32 unreachable',
        stage: MachineCommandStage.transportFailure,
      );
    } catch (error) {
      return DiamondCamResult.failure(
        'GET /info failed: $error',
        stage: MachineCommandStage.transportFailure,
      );
    }
  }

  Future<DiamondCamResult> rotate({required num angle, required num speed}) {
    final clampedAngle = angle.toDouble().clamp(calibration.minAngle, calibration.maxAngle);
    final clampedSpeed = speed.toDouble().clamp(1, calibration.maxSpeed);
    return _command(
      MachineEndpointConfig.rotatePath,
      DiamondCamProtocol.rotateBody(angle: clampedAngle, speed: clampedSpeed),
      acceptedMessage:
          'Command accepted (success:true). Commanded ${clampedAngle.round()}°. Physical movement unverified.',
    );
  }

  Future<DiamondCamResult> continuous({required String direction, required num speed}) {
    final dir = direction.trim().toLowerCase();
    if (!DiamondCamProtocol.isContinuousDirection(dir)) {
      return Future.value(DiamondCamResult.failure(
        'Direction must be cw or ccw',
        stage: MachineCommandStage.notSent,
      ));
    }
    final clampedSpeed = speed.toDouble().clamp(1, calibration.maxSpeed);
    return _command(
      MachineEndpointConfig.rotateContinuousPath,
      DiamondCamProtocol.continuousBody(direction: dir, speed: clampedSpeed),
      acceptedMessage: dir == DiamondCamProtocol.directionCcw
          ? 'Command accepted (success:true). direction=ccw. Physical movement unverified.'
          : 'Command accepted (success:true). direction=cw. Physical movement unverified.',
    );
  }

  Future<DiamondCamResult> stop() {
    return _command(
      MachineEndpointConfig.rotateStopPath,
      const {},
      acceptedMessage:
          'Command accepted (success:true). Stop requested. Physical movement unverified.',
    );
  }

  Future<DiamondCamResult> setLight({required bool state, required int intensity}) {
    final clamped = intensity.clamp(0, calibration.maxLightIntensity);
    return _command(
      MachineEndpointConfig.lightPath,
      DiamondCamProtocol.lightBody(state: state, intensity: clamped),
      acceptedMessage:
          'Command accepted (success:true). Light command applied in firmware. Physical light response unverified.',
    );
  }

  Future<DiamondCamResult> reset() {
    return _command(
      MachineEndpointConfig.resetPath,
      const {},
      acceptedMessage:
          'Command accepted (success:true). Reset requested. Reconnecting with /health /info /status…',
    );
  }

  Future<DiamondCamResult> home() async {
    return DiamondCamResult.failure(
      'Home sensor not installed',
      stage: MachineCommandStage.notSent,
    );
  }

  Future<DiamondCamResult> _command(
    String path,
    Map<String, Object?> body, {
    required String acceptedMessage,
  }) async {
    try {
      final response = await _http.post(path, body);
      final parsed = _http.parser.parseCommand(response.statusCode, response.body);
      if (!parsed.accepted) {
        return DiamondCamResult.failure(
          'POST $path: ${parsed.message}',
          statusCode: response.statusCode,
          body: response.body,
          stage: parsed.stage,
        );
      }
      return DiamondCamResult(
        ok: true,
        message: '$acceptedMessage Machine response: ${response.body}',
        statusCode: response.statusCode,
        body: response.body,
        commandAccepted: true,
        physicalVerified: false,
        stage: MachineCommandStage.physicalUnverified,
      );
    } on TimeoutException {
      return DiamondCamResult.failure(
        'Machine did not respond in time',
        stage: MachineCommandStage.transportFailure,
      );
    } on SocketException {
      return DiamondCamResult.failure(
        'ESP32 unreachable',
        stage: MachineCommandStage.transportFailure,
      );
    } catch (error) {
      return DiamondCamResult.failure(
        'Command was not sent: $error',
        stage: MachineCommandStage.notSent,
      );
    }
  }
}
