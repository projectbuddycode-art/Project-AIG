import 'package:flutter/foundation.dart';

/// Represents a hardware device discovered by the transport layer.
@immutable
class DeviceInfo {
  final String id;
  final String name;
  final int rssi;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
  });

  DeviceInfo copyWith({String? id, String? name, int? rssi}) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeviceInfo &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            rssi == other.rssi;
  }

  @override
  int get hashCode => Object.hash(id, name, rssi);
}
