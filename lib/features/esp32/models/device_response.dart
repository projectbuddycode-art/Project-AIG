import 'package:flutter/foundation.dart';

/// Represents a typed response from the device protocol layer.
@immutable
class DeviceResponse {
  final DeviceResponseType type;
  final List<int> payload;

  const DeviceResponse({
    required this.type,
    this.payload = const [],
  });
}

enum DeviceResponseType {
  acknowledgement,
  status,
  error,
  capabilities,
  firmwareInfo,
  diagnostics,
}
