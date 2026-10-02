import 'dart:io';

import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';

/// Runtime HTTP target. Paths come from [DiamondCamProtocol] only.
class MachineEndpointConfig {
  MachineEndpointConfig({
    this.scheme = DiamondCamProtocol.defaultScheme,
    this.host = DiamondCamProtocol.defaultHost,
    this.port = DiamondCamProtocol.defaultPort,
    this.basePath = defaultBasePath,
  });

  static const String defaultScheme = DiamondCamProtocol.defaultScheme;
  static const String defaultHost = DiamondCamProtocol.defaultHost;
  static const int defaultPort = DiamondCamProtocol.defaultPort;
  static const String defaultBasePath = '';

  static const String wifiSsid = DiamondCamProtocol.wifiSsid;
  static const String wifiPasswordHint = DiamondCamProtocol.wifiPasswordHint;

  static const String healthPath = DiamondCamProtocol.healthPath;
  static const String infoPath = DiamondCamProtocol.infoPath;
  static const String statusPath = DiamondCamProtocol.statusPath;
  static const String rotatePath = DiamondCamProtocol.rotatePath;
  static const String rotateContinuousPath = DiamondCamProtocol.rotateContinuousPath;
  static const String rotateStopPath = DiamondCamProtocol.rotateStopPath;
  static const String lightPath = DiamondCamProtocol.lightPath;
  static const String resetPath = DiamondCamProtocol.resetPath;

  static const double minAngle = 0;
  static const double maxAngle = 180;
  static const int minIntensity = 0;
  static const int maxIntensity = 100;
  static const String directionCw = DiamondCamProtocol.directionCw;
  static const String directionCcw = DiamondCamProtocol.directionCcw;

  static MachineEndpointConfig current = MachineEndpointConfig();

  String scheme;
  String host;
  int port;
  String basePath;

  factory MachineEndpointConfig.defaults() => MachineEndpointConfig();

  Uri get baseUri => Uri(scheme: scheme, host: host, port: port, path: _normalizeBasePath());

  String get originForLog => '$scheme://$host:$port';

  Uri uriFor(String endpoint) {
    final path = _joinPath(endpoint);
    return Uri(scheme: scheme, host: host, port: port, path: path);
  }

  String describe(Uri uri) => '$scheme://$host:${uri.hasPort ? uri.port : port}${uri.path}';

  void apply({
    required String host,
    required int port,
    String scheme = defaultScheme,
    String basePath = defaultBasePath,
  }) {
    this.scheme = scheme.trim().isEmpty ? defaultScheme : scheme.trim();
    this.host = host.trim().isEmpty ? defaultHost : host.trim();
    this.port = port <= 0 || port > 65535 ? defaultPort : port;
    this.basePath = basePath.trim();
  }

  String _normalizeBasePath() {
    if (basePath.isEmpty) {
      return '';
    }
    final withSlash = basePath.startsWith('/') ? basePath : '/$basePath';
    return withSlash.endsWith('/') ? withSlash.substring(0, withSlash.length - 1) : withSlash;
  }

  String _joinPath(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final prefix = _normalizeBasePath();
    if (prefix.isEmpty) {
      return normalizedEndpoint;
    }
    return '$prefix$normalizedEndpoint'.replaceAll('//', '/');
  }
}

class MachineConfig {
  static String get host => MachineEndpointConfig.current.host;
  static int get port => MachineEndpointConfig.current.port;
  static Uri get baseUri => MachineEndpointConfig.current.baseUri;
}

bool machineHttpDebugEnabled() {
  return !const bool.fromEnvironment('dart.vm.product') ||
      Platform.environment['AIG_MACHINE_DEBUG'] == '1';
}
