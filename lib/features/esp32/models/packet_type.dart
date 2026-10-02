/// Defines the transport-independent packet types used by the protocol.
enum PacketType {
  command,
  response,
  ack,
  nack,
  handshake,
  heartbeat,
  reserved,
}

extension PacketTypeX on PacketType {
  int get id {
    switch (this) {
      case PacketType.command:
        return 0x01;
      case PacketType.response:
        return 0x02;
      case PacketType.ack:
        return 0x03;
      case PacketType.nack:
        return 0x04;
      case PacketType.handshake:
        return 0x05;
      case PacketType.heartbeat:
        return 0x06;
      case PacketType.reserved:
        return 0xFF;
    }
  }

  static PacketType fromId(int id) {
    switch (id) {
      case 0x01:
        return PacketType.command;
      case 0x02:
        return PacketType.response;
      case 0x03:
        return PacketType.ack;
      case 0x04:
        return PacketType.nack;
      case 0x05:
        return PacketType.handshake;
      case 0x06:
        return PacketType.heartbeat;
      default:
        return PacketType.reserved;
    }
  }
}
