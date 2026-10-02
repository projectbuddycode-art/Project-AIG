import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/models/device_response.dart';

/// Responsible for encoding commands and decoding raw transport packets.
class DeviceProtocol {
  const DeviceProtocol();

  /// Encodes a command into device transport bytes.
  List<int> encode(DeviceCommand command) {
    final int header = _headerForType(command.type);
    return [header, ...command.payload];
  }

  /// Decodes raw transport bytes into a typed device response.
  DeviceResponse decode(List<int> rawData) {
    if (rawData.isEmpty) {
      return const DeviceResponse(type: DeviceResponseType.error, payload: []);
    }

    final responseType = _typeForHeader(rawData[0]);
    final payload = rawData.length > 1 ? rawData.sublist(1) : <int>[];
    return DeviceResponse(type: responseType, payload: payload);
  }

  int _headerForType(DeviceCommandType type) {
    switch (type) {
      case DeviceCommandType.connection:
        return 0x01;
      case DeviceCommandType.rotation:
        return 0x02;
      case DeviceCommandType.lighting:
        return 0x03;
      case DeviceCommandType.capture:
        return 0x04;
      case DeviceCommandType.status:
        return 0x05;
      case DeviceCommandType.firmware:
        return 0x06;
      case DeviceCommandType.diagnostics:
        return 0x07;
    }
  }

  DeviceResponseType _typeForHeader(int header) {
    switch (header) {
      case 0x01:
        return DeviceResponseType.acknowledgement;
      case 0x05:
        return DeviceResponseType.status;
      case 0x06:
        return DeviceResponseType.firmwareInfo;
      case 0x07:
        return DeviceResponseType.diagnostics;
      case 0xFF:
        return DeviceResponseType.error;
      default:
        return DeviceResponseType.error;
    }
  }
}
