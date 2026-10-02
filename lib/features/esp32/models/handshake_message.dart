import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/protocol_version.dart';

@immutable
class HandshakeMessage {
  final ProtocolVersion clientVersion;
  final String deviceIdentifier;
  final ProtocolVersion? deviceVersion;

  const HandshakeMessage({
    required this.clientVersion,
    required this.deviceIdentifier,
    this.deviceVersion,
  });

  List<int> toBytes() {
    final identifierBytes = utf8.encode(deviceIdentifier);
    return [
      clientVersion.major,
      clientVersion.minor,
      clientVersion.patch,
      identifierBytes.length,
      ...identifierBytes,
      if (deviceVersion != null) ...[
        deviceVersion!.major,
        deviceVersion!.minor,
        deviceVersion!.patch,
      ],
    ];
  }

  factory HandshakeMessage.fromBytes(List<int> data) {
    if (data.length < 4) {
      throw FormatException('Handshake packet too short');
    }

    final clientVersion = ProtocolVersion(
      major: data[0],
      minor: data[1],
      patch: data[2],
    );
    final identifierLength = data[3];
    final identifierEnd = 4 + identifierLength;

    if (data.length < identifierEnd) {
      throw FormatException('Handshake packet contains invalid identifier length');
    }

    final identifier = utf8.decode(data.sublist(4, identifierEnd));
    ProtocolVersion? deviceVersion;

    if (data.length >= identifierEnd + 3) {
      deviceVersion = ProtocolVersion(
        major: data[identifierEnd],
        minor: data[identifierEnd + 1],
        patch: data[identifierEnd + 2],
      );
    }

    return HandshakeMessage(
      clientVersion: clientVersion,
      deviceIdentifier: identifier,
      deviceVersion: deviceVersion,
    );
  }
}
