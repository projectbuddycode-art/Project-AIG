import 'package:flutter/foundation.dart';

/// Configures reconnect behavior for the device connection manager.
@immutable
class ReconnectPolicy {
  final int maxRetries;
  final Duration retryInterval;
  final double backoffFactor;

  const ReconnectPolicy({
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 2),
    this.backoffFactor = 1.5,
  });
}
