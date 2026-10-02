import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/protocol_version.dart';

/// Represents firmware metadata reported by the device.
@immutable
class FirmwareInfo {
  final ProtocolVersion firmwareVersion;
  final String buildNumber;
  final DateTime? releaseDate;
  final String hardwareVersion;
  final String commitHash;

  const FirmwareInfo({
    required this.firmwareVersion,
    required this.buildNumber,
    this.releaseDate,
    this.hardwareVersion = '',
    this.commitHash = '',
  });

  FirmwareInfo copyWith({
    ProtocolVersion? firmwareVersion,
    String? buildNumber,
    DateTime? releaseDate,
    String? hardwareVersion,
    String? commitHash,
  }) {
    return FirmwareInfo(
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      releaseDate: releaseDate ?? this.releaseDate,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      commitHash: commitHash ?? this.commitHash,
    );
  }
}
