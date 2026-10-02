import 'package:flutter/foundation.dart';

/// Represents a protocol version used by the device communication layer.
@immutable
class ProtocolVersion {
  final int major;
  final int minor;
  final int patch;

  const ProtocolVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProtocolVersion &&
            runtimeType == other.runtimeType &&
            major == other.major &&
            minor == other.minor &&
            patch == other.patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);
}
