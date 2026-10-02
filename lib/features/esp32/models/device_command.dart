import 'package:flutter/foundation.dart';

/// Represents a device command category and payload for the communication layer.
@immutable
class DeviceCommand {
  final DeviceCommandType type;
  final List<int> payload;
  final int priority;

  const DeviceCommand({
    required this.type,
    this.payload = const [],
    this.priority = 0,
  });
}

/// Defines categories for device commands.
enum DeviceCommandType {
  connection,
  rotation,
  lighting,
  capture,
  status,
  firmware,
  diagnostics,
}
