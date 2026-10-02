import 'dart:async';
import 'dart:io';

import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_http_client.dart';

class MachineController {
  MachineController({
    required this.rotation,
    required this.lighting,
    required this.presets,
    required this.status,
    required this.safety,
    MachineHttpClient? httpClient,
  }) : _http = httpClient ?? MachineHttpClient();

  final RotationController rotation;
  final LightingController lighting;
  final PresetController presets;
  final MachineStatusController status;
  final SafetyController safety;
  final MachineHttpClient _http;

  Future<DeviceConnectionState> verifyConnection({String deviceName = 'ESP32 Machine'}) async {
    try {
      final response = await _http.get(MachineEndpointConfig.statusPath);
      if (response.statusCode != HttpStatus.ok) {
        return DeviceConnectionState.error(
          'HTTP ${response.statusCode} from ${MachineEndpointConfig.current.describe(response.uri)}',
          deviceName: deviceName,
        );
      }
      final parsed = _http.parser.parse(response.body);
      if (!parsed.accepted) {
        return DeviceConnectionState.connectedUnverified(
          deviceName,
          rssi: -55,
          message:
              'HTTP ${MachineEndpointConfig.current.originForLog}/status responded, but payload did not match DiamondCam contract (connected, rotation, light, intensity, motorRunning). ${parsed.identityReason}',
          lastVerifiedAt: DateTime.now(),
        );
      }
      if (parsed.rotation != null) {
        rotation.syncCommandedAngle(parsed.rotation!.toDouble());
      }
      return DeviceConnectionState.connected(
        deviceName,
        -55,
        firmwareVersion: null,
        lastVerifiedAt: DateTime.now(),
      );
    } on TimeoutException {
      return DeviceConnectionState.unreachable(deviceName, 'Machine did not respond within 5s');
    } on SocketException catch (error) {
      return DeviceConnectionState.unreachable(deviceName, error.message);
    } catch (error) {
      return DeviceConnectionState.error('Unable to validate machine: $error', deviceName: deviceName);
    }
  }

  /// Diagnostics use only real firmware endpoints — never /firmware, /home, /preset, /diagnostics.
  Future<Map<String, dynamic>> runDiagnostics({String deviceName = 'ESP32 Machine'}) async {
    final origin = MachineEndpointConfig.current.originForLog;
    final report = <String, dynamic>{
      'deviceName': deviceName,
      'origin': origin,
      'httpReachable': false,
      'machineIdentityVerified': false,
      'firmwareVersion': null,
      'statusVerified': false,
      'rawStatusBody': null,
      'pass': false,
      'message': 'Diagnostics did not complete.',
      'firmware': 'UNAVAILABLE',
      'home': 'UNAVAILABLE',
      'preset': 'UNAVAILABLE',
    };

    try {
      final statusResponse = await _http.get(MachineEndpointConfig.statusPath);
      report['httpReachable'] = statusResponse.statusCode == HttpStatus.ok;
      report['rawStatusBody'] = statusResponse.body;
      report['transport'] = report['httpReachable'] == true ? 'PASS' : 'FAIL';
      if (statusResponse.statusCode != HttpStatus.ok) {
        report['identity'] = 'FAIL';
        report['status'] = 'FAIL';
        report['rotation'] = 'FAIL';
        report['lighting'] = 'FAIL';
        report['stop'] = 'FAIL';
        report['message'] = 'HTTP ${statusResponse.statusCode} from $origin${MachineEndpointConfig.statusPath}';
        return report;
      }

      final parsed = _http.parser.parse(statusResponse.body);
      report['machineIdentityVerified'] = parsed.accepted;
      report['statusVerified'] = parsed.accepted;
      report['identity'] = parsed.accepted ? 'PASS' : 'FAIL';
      report['status'] = parsed.accepted ? 'PASS' : 'FAIL';
      report['statusContract'] = parsed.accepted ? 'PASS' : 'FAIL';
      report['identityReason'] = parsed.identityReason;
      report['firmware'] = 'UNAVAILABLE';

      if (parsed.accepted && parsed.rotation != null) {
        rotation.syncCommandedAngle(parsed.rotation!.toDouble());
      }

      // Safe rotate path probe: re-command current angle (or 0) at low speed — no large move.
      final probeAngle = (parsed.rotation ?? 0).toDouble().clamp(
            MachineEndpointConfig.minAngle,
            MachineEndpointConfig.maxAngle,
          );
      report['rotation'] = await _probeCapability(
        MachineEndpointConfig.rotatePath,
        {'angle': probeAngle, 'speed': 1},
      );
      report['lighting'] = await _probeCapability(
        MachineEndpointConfig.lightPath,
        const {'state': false, 'intensity': 0},
      );
      report['stop'] = await _probeCapability(
        MachineEndpointConfig.rotateStopPath,
        const {},
      );

      final requiredPass = report['transport'] == 'PASS' &&
          report['identity'] == 'PASS' &&
          report['rotation'] == 'PASS' &&
          report['lighting'] == 'PASS' &&
          report['stop'] == 'PASS';
      report['pass'] = requiredPass;
      report['message'] = requiredPass
          ? 'Diagnostics passed at $origin (firmware version unavailable on this firmware)'
          : 'Diagnostics failed at $origin. Transport ${report['transport']}, identity ${report['identity']} (${parsed.identityReason}), rotation ${report['rotation']}, lighting ${report['lighting']}, stop ${report['stop']}. Firmware unavailable (no /firmware endpoint).';
      return report;
    } on TimeoutException {
      report['message'] = 'Machine did not respond within 5s during diagnostics at $origin.';
      return report;
    } on SocketException catch (error) {
      report['message'] = 'Socket error during diagnostics at $origin: ${error.message}';
      return report;
    } catch (error) {
      report['message'] = 'Diagnostics error at $origin: $error';
      return report;
    }
  }

  Future<String> _probeCapability(String path, Map<String, Object?> body) async {
    try {
      final response = await _http.post(path, body);
      return response.accepted ? 'PASS' : 'FAIL';
    } catch (_) {
      return 'FAIL';
    }
  }

  /// Sends /reset, waits for the ESP32 to restart, then re-verifies /status.
  Future<DeviceConnectionState> resetAndReconnect({String deviceName = 'DiamondCam'}) async {
    try {
      final response = await _http.post(MachineEndpointConfig.resetPath, const {});
      if (!response.accepted && response.statusCode < 200) {
        return DeviceConnectionState.error('Reset command was not accepted', deviceName: deviceName);
      }
    } catch (_) {
      // ESP.restart() often closes the socket before a JSON body is delivered.
    }
    await Future<void>.delayed(const Duration(seconds: 3));
    DeviceConnectionState last = DeviceConnectionState.reconnecting(deviceName);
    for (var attempt = 1; attempt <= 6; attempt++) {
      last = await verifyConnection(deviceName: deviceName);
      if (last.status == ConnectionStatus.connected ||
          last.status == ConnectionStatus.connectedUnverified) {
        return last;
      }
      await Future<void>.delayed(Duration(milliseconds: backoffMs(attempt)));
    }
    return last;
  }

  Future<bool> resetMachine() async {
    final state = await resetAndReconnect();
    return state.status == ConnectionStatus.connected;
  }
}
