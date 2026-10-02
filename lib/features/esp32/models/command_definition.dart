import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/command_category.dart';

@immutable
class CommandDefinition {
  final CommandCategory category;
  final int commandId;
  final String name;
  final String description;

  const CommandDefinition({
    required this.category,
    required this.commandId,
    required this.name,
    this.description = '',
  });

  CommandDefinition withDescription(String description) {
    return CommandDefinition(
      category: category,
      commandId: commandId,
      name: name,
      description: description,
    );
  }

  static const CommandDefinition handshake = CommandDefinition(
    category: CommandCategory.connection,
    commandId: 0x00,
    name: 'Handshake',
    description: 'Initial transport-independent protocol handshake.',
  );

  static const CommandDefinition ping = CommandDefinition(
    category: CommandCategory.connection,
    commandId: 0x01,
    name: 'Ping',
    description: 'Verify connectivity and device responsiveness.',
  );

  static const CommandDefinition getStatus = CommandDefinition(
    category: CommandCategory.status,
    commandId: 0x02,
    name: 'Get Status',
    description: 'Request current device operational state.',
  );

  static const CommandDefinition setLighting = CommandDefinition(
    category: CommandCategory.lighting,
    commandId: 0x03,
    name: 'Set Lighting',
    description: 'Update lighting intensity or mode.',
  );

  static const CommandDefinition rotate = CommandDefinition(
    category: CommandCategory.rotation,
    commandId: 0x04,
    name: 'Rotate',
    description: 'Rotate equipment to a target orientation.',
  );

  static const CommandDefinition captureImage = CommandDefinition(
    category: CommandCategory.capture,
    commandId: 0x05,
    name: 'Capture Image',
    description: 'Trigger an image capture sequence.',
  );

  static const CommandDefinition requestFirmwareInfo = CommandDefinition(
    category: CommandCategory.firmware,
    commandId: 0x06,
    name: 'Request Firmware Info',
    description: 'Request firmware metadata and build version.',
  );

  static const CommandDefinition runDiagnostics = CommandDefinition(
    category: CommandCategory.diagnostics,
    commandId: 0x07,
    name: 'Run Diagnostics',
    description: 'Execute onboard diagnostic checks.',
  );
}
