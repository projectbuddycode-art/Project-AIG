import 'dart:async';

import 'package:aig/features/esp32/services/device_logger.dart';

/// Provides heartbeat status updates for device connectivity.
class HeartbeatService {
  final DeviceLogger _logger;
  final StreamController<bool> _statusController = StreamController.broadcast();
  Timer? _timer;

  HeartbeatService({required DeviceLogger logger}) : _logger = logger;

  Stream<bool> get status => _statusController.stream;

  void start({Duration interval = const Duration(seconds: 15)}) {
    stop();
    _timer = Timer.periodic(interval, (_) {
      _logger.log('Heartbeat tick');
      _statusController.add(true);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _statusController.add(false);
  }
}
