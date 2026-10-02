/// Represents high-level command categories supported by the device protocol.
enum CommandCategory {
  connection,
  device,
  rotation,
  lighting,
  cameraTrigger,
  capture,
  preset,
  status,
  diagnostics,
  firmware,
  ota,
  system,
}

extension CommandCategoryX on CommandCategory {
  String get name {
    switch (this) {
      case CommandCategory.connection:
        return 'Connection';
      case CommandCategory.device:
        return 'Device';
      case CommandCategory.rotation:
        return 'Rotation';
      case CommandCategory.lighting:
        return 'Lighting';
      case CommandCategory.cameraTrigger:
        return 'Camera Trigger';
      case CommandCategory.capture:
        return 'Capture';
      case CommandCategory.preset:
        return 'Preset';
      case CommandCategory.status:
        return 'Status';
      case CommandCategory.diagnostics:
        return 'Diagnostics';
      case CommandCategory.firmware:
        return 'Firmware';
      case CommandCategory.ota:
        return 'OTA';
      case CommandCategory.system:
        return 'System';
    }
  }
}
