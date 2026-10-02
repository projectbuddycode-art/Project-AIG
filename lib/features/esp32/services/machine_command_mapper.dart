import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';

class MappedMachineRequest {
  const MappedMachineRequest({
    required this.method,
    required this.path,
    required this.body,
    this.urgent = false,
  });

  final String method;
  final String path;
  final Map<String, Object?> body;
  final bool urgent;
}

/// Maps internal binary command packets onto the DiamondCam ESP32 HTTP contract.
///
/// Packet layout after DeviceProtocol.encode:
///   [typeHeader, commandId, opcodeOrDir, ...]
///
/// Emits only fields the firmware accepts. Does not call /firmware, /home,
/// /preset, or /diagnostics.
class MachineCommandMapper {
  MappedMachineRequest? map(List<int> data) {
    if (data.isEmpty) {
      return null;
    }
    final header = data[0];
    final payload = data.length > 1 ? data.sublist(1) : <int>[];
    switch (header) {
      case 0x05:
        return const MappedMachineRequest(method: 'GET', path: DiamondCamProtocol.statusPath, body: {});
      case 0x02:
        return _mapRotation(payload);
      case 0x03:
        return _mapLighting(payload);
      case 0x08:
        return const MappedMachineRequest(method: 'POST', path: DiamondCamProtocol.resetPath, body: {});
      case 0x06:
        // No /firmware on DiamondCam firmware.
        return null;
      default:
        return null;
    }
  }

  MappedMachineRequest? _mapRotation(List<int> payload) {
    // payload: [commandId, opcode/dir, continuous?, speedLo, speedHi, ...]
    final opcode = payload.length >= 2 ? payload[1] : -1;
    final continuous = payload.length >= 3 && payload[2] == 1;
    final speed = payload.length >= 5 ? (payload[3] | (payload[4] << 8)) / 100.0 : 0.0;
    final clockwise = payload.length >= 2 ? payload[1] == 1 : true;

    // Continuous must be checked before STOP: CCW uses dir byte 0, which is also stop opcode.
    if (continuous) {
      return MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.rotateContinuousPath,
        body: {
          'direction': clockwise
              ? MachineEndpointConfig.directionCw
              : MachineEndpointConfig.directionCcw,
          'speed': speed,
        },
      );
    }

    if (opcode == 0x00 || opcode == 0xFF) {
      return const MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.rotateStopPath,
        body: {},
        urgent: true,
      );
    }

    // Legacy home opcode — no home sensor and no /home endpoint.
    if (opcode == 0x20) {
      return null;
    }

    if (opcode == 0x10 && payload.length >= 4) {
      final rawAngle = payload[2] | (payload[3] << 8);
      final angle = rawAngle.clamp(
        MachineEndpointConfig.minAngle.round(),
        MachineEndpointConfig.maxAngle.round(),
      );
      final angleSpeed = payload.length >= 6
          ? (payload[4] | (payload[5] << 8)) / 100.0
          : speed;
      return MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.rotatePath,
        body: {'angle': angle, 'speed': angleSpeed},
      );
    }

    // Absolute angle may also be carried in stepDegrees bytes for legacy packets.
    if ((opcode == 0 || opcode == 1) && payload.length >= 7) {
      final angle = ((payload[5] | (payload[6] << 8)) / 100.0).clamp(
        MachineEndpointConfig.minAngle,
        MachineEndpointConfig.maxAngle,
      );
      return MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.rotatePath,
        body: {'angle': angle, 'speed': speed},
      );
    }

    // Unknown rotation packet — do not command angle 0 (that would fake HOME).
    return null;
  }

  MappedMachineRequest? _mapLighting(List<int> payload) {
    // payload: [commandId, opcode, ...]
    final opcode = payload.length >= 2 ? payload[1] : -1;

    if (opcode == 0x10) {
      final on = payload.length >= 3 && payload[2] == 0x01;
      final intensity = payload.length >= 4
          ? payload[3].clamp(MachineEndpointConfig.minIntensity, MachineEndpointConfig.maxIntensity)
          : (on ? MachineEndpointConfig.maxIntensity : MachineEndpointConfig.minIntensity);
      return MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.lightPath,
        body: {'state': on, 'intensity': intensity},
      );
    }

    // Master brightness opcode: intensity 0–100 in payload[2].
    if (opcode == 0x01 && payload.length >= 3) {
      final intensity =
          payload[2].clamp(MachineEndpointConfig.minIntensity, MachineEndpointConfig.maxIntensity);
      return MappedMachineRequest(
        method: 'POST',
        path: MachineEndpointConfig.lightPath,
        body: {
          'state': intensity > 0,
          'intensity': intensity,
        },
      );
    }

    // Zones / color temperature are unsupported by firmware.
    return null;
  }
}
