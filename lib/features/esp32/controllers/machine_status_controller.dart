import 'dart:async';

import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/models/device_response.dart';
import 'package:aig/features/esp32/services/command_executor.dart';

/// Responsible for requesting and parsing machine status telemetry.
class MachineStatusController {
  final CommandExecutor _executor;
  Timer? _dailyDiagnosticsTimer;
  bool _diagnosticsScheduled = false;
  DateTime? lastDiagnosticsAt;

  MachineStatusController(this._executor);

  Stream<DeviceResponse> get statusStream => _executor.responses;

  Future<void> requestStatus() async {
    final payload = [0x02]; // re-use existing command id for getStatus
    lastDiagnosticsAt = DateTime.now();
    await _executor.enqueue(DeviceCommand(type: DeviceCommandType.status, payload: payload));
  }

  void beginDailyDiagnostics({Duration interval = const Duration(days: 1)}) {
    if (_diagnosticsScheduled) {
      return;
    }
    _diagnosticsScheduled = true;
    _dailyDiagnosticsTimer = Timer.periodic(interval, (_) async {
      await requestStatus();
    });
    Future<void>(() async => await requestStatus());
  }

  void stopDailyDiagnostics() {
    _dailyDiagnosticsTimer?.cancel();
    _dailyDiagnosticsTimer = null;
    _diagnosticsScheduled = false;
  }
}
