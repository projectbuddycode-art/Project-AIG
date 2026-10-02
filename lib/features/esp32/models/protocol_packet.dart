import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/command_category.dart';
import 'package:aig/features/esp32/models/error_code.dart';
import 'package:aig/features/esp32/models/packet_type.dart';
import 'package:aig/features/esp32/models/protocol_error.dart';
import 'package:aig/features/esp32/models/protocol_version.dart';
import 'package:aig/features/esp32/models/response_code.dart';

@immutable
class ProtocolPacket {
  static const int headerLength = 7;

  final PacketType packetType;
  final ProtocolVersion version;
  final CommandCategory category;
  final int subtype;
  final int sequence;
  final ResponseCode? responseCode;
  final ErrorCode? errorCode;
  final List<int> payload;

  const ProtocolPacket({
    required this.packetType,
    required this.version,
    required this.category,
    required this.subtype,
    required this.sequence,
    this.responseCode,
    this.errorCode,
    this.payload = const [],
  });

  bool get isCommand => packetType == PacketType.command;
  bool get isResponse => packetType == PacketType.response;
  bool get isAck => packetType == PacketType.ack;
  bool get isNack => packetType == PacketType.nack;
  bool get isHandshake => packetType == PacketType.handshake;
  bool get isHeartbeat => packetType == PacketType.heartbeat;

  List<int> toBytes() {
    final bytes = <int>[
      packetType.id,
      version.major,
      version.minor,
      version.patch,
      category.index,
      subtype,
      sequence,
    ];

    if (isNack && errorCode != null) {
      bytes.add(errorCode!.index);
    }

    bytes.addAll(payload);
    return bytes;
  }

  factory ProtocolPacket.fromBytes(List<int> rawData) {
    if (rawData.length < headerLength) {
      throw ProtocolException(
        code: ErrorCode.malformedPayload,
        message: 'Packet too short for protocol header.',
      );
    }

    final packetType = PacketTypeX.fromId(rawData[0]);
    final version = ProtocolVersion(
      major: rawData[1],
      minor: rawData[2],
      patch: rawData[3],
    );
    final categoryIndex = rawData[4];
    final subtype = rawData[5];
    final sequence = rawData[6];

    final category = CommandCategory.values.elementAt(
      categoryIndex.clamp(0, CommandCategory.values.length - 1),
    );

    if (packetType == PacketType.nack) {
      if (rawData.length < headerLength + 1) {
        throw ProtocolException(
          code: ErrorCode.malformedPayload,
          message: 'NACK packet missing error code.',
        );
      }
      final errorCode = ErrorCode.values.elementAt(
        rawData[7].clamp(0, ErrorCode.values.length - 1),
      );
      return ProtocolPacket(
        packetType: packetType,
        version: version,
        category: category,
        subtype: subtype,
        sequence: sequence,
        errorCode: errorCode,
        payload: rawData.length > headerLength + 1 ? rawData.sublist(headerLength + 1) : const [],
      );
    }

    final payload = rawData.length > headerLength ? rawData.sublist(headerLength) : const <int>[];
    final responseCode = packetType == PacketType.response
        ? ResponseCode.values.elementAt(subtype.clamp(0, ResponseCode.values.length - 1))
        : null;

    return ProtocolPacket(
      packetType: packetType,
      version: version,
      category: category,
      subtype: subtype,
      sequence: sequence,
      responseCode: responseCode,
      payload: payload,
    );
  }
}
