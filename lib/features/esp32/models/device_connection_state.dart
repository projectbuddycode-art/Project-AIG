import 'package:flutter/foundation.dart';

/// Represents the connection state exposed to the UI.
@immutable
class DeviceConnectionState {
  final ConnectionStatus status;
  final String? deviceName;
  final int? rssi;
  final String? message;
  final String? firmwareVersion;
  final DateTime? lastVerifiedAt;

  const DeviceConnectionState({
    required this.status,
    this.deviceName,
    this.rssi,
    this.message,
    this.firmwareVersion,
    this.lastVerifiedAt,
  });

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isReachable =>
      status == ConnectionStatus.connected ||
      status == ConnectionStatus.connectedUnverified ||
      status == ConnectionStatus.transportReachable ||
      status == ConnectionStatus.verifying ||
      status == ConnectionStatus.connecting;

  DeviceConnectionState copyWith({
    ConnectionStatus? status,
    String? deviceName,
    int? rssi,
    String? message,
    String? firmwareVersion,
    DateTime? lastVerifiedAt,
  }) {
    return DeviceConnectionState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      rssi: rssi ?? this.rssi,
      message: message ?? this.message,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }

  factory DeviceConnectionState.idle() => const DeviceConnectionState(status: ConnectionStatus.idle);

  factory DeviceConnectionState.scanning() => const DeviceConnectionState(status: ConnectionStatus.scanning);

  factory DeviceConnectionState.connecting(String deviceName) => DeviceConnectionState(
        status: ConnectionStatus.connecting,
        deviceName: deviceName,
      );

  factory DeviceConnectionState.connectedUnverified(String deviceName, {int? rssi, String? message, DateTime? lastVerifiedAt}) =>
      DeviceConnectionState(
        status: ConnectionStatus.connectedUnverified,
        deviceName: deviceName,
        rssi: rssi,
        message: message,
        lastVerifiedAt: lastVerifiedAt,
      );

  factory DeviceConnectionState.verifying(String deviceName, {int? rssi}) => DeviceConnectionState(
        status: ConnectionStatus.verifying,
        deviceName: deviceName,
        rssi: rssi,
        message: 'Verifying machine identity',
      );

  factory DeviceConnectionState.connected(
    String deviceName,
    int rssi, {
    String? firmwareVersion,
    DateTime? lastVerifiedAt,
  }) =>
      DeviceConnectionState(
        status: ConnectionStatus.connected,
        deviceName: deviceName,
        rssi: rssi,
        firmwareVersion: firmwareVersion,
        lastVerifiedAt: lastVerifiedAt,
      );

  factory DeviceConnectionState.reconnecting(String deviceName) => DeviceConnectionState(
        status: ConnectionStatus.reconnecting,
        deviceName: deviceName,
      );

  factory DeviceConnectionState.disconnected(String? deviceName) => DeviceConnectionState(
        status: ConnectionStatus.disconnected,
        deviceName: deviceName,
      );

  factory DeviceConnectionState.unreachable(String? deviceName, [String? message]) => DeviceConnectionState(
        status: ConnectionStatus.unreachable,
        deviceName: deviceName,
        message: message,
      );

  factory DeviceConnectionState.error(String message, {String? deviceName}) => DeviceConnectionState(
        status: ConnectionStatus.error,
        deviceName: deviceName,
        message: message,
      );

  factory DeviceConnectionState.failure(String message) => DeviceConnectionState(
        status: ConnectionStatus.failure,
        message: message,
      );
}

enum ConnectionStatus {
  idle,
  scanning,
  connecting,
  transportReachable,
  connectedUnverified,
  verifying,
  connected,
  reconnecting,
  disconnected,
  error,
  unreachable,
  failure,
}

String connectionStatusLabel(ConnectionStatus status) {
  switch (status) {
    case ConnectionStatus.connected:
      return 'Protocol Verified';
    case ConnectionStatus.connectedUnverified:
    case ConnectionStatus.transportReachable:
      return 'ESP32 Reachable · Protocol Unverified';
    case ConnectionStatus.verifying:
      return 'Verifying';
    case ConnectionStatus.connecting:
    case ConnectionStatus.reconnecting:
    case ConnectionStatus.scanning:
      return 'Connecting';
    case ConnectionStatus.disconnected:
    case ConnectionStatus.idle:
      return 'Disconnected';
    case ConnectionStatus.error:
    case ConnectionStatus.failure:
      return 'Error';
    case ConnectionStatus.unreachable:
      return 'Unreachable';
  }
}
