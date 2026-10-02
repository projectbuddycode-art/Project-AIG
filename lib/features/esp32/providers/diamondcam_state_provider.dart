import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/esp32/models/machine_calibration.dart';
import 'package:aig/features/esp32/models/machine_info.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';
import 'package:aig/features/esp32/providers/device_connection_manager_provider.dart';
import 'package:aig/features/esp32/providers/machine_controllers_providers.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/esp32/services/diamondcam_service.dart';

@immutable
class DiamondCamUiState {
  const DiamondCamUiState({
    this.phase = DiamondCamPhase.disconnected,
    this.message,
    this.commandedAngle = 0,
    this.motorRunning = false,
    this.lightOn = false,
    this.intensity = 0,
    this.selectedAngle = 90,
    this.selectedSpeed = 30,
    this.busy = false,
    this.calibrationStatus = 'Unconfirmed',
    this.healthOk = false,
    this.info,
    this.lastRawResponse,
    this.positiveDirectionIsCW,
  });

  final DiamondCamPhase phase;
  final String? message;
  final double commandedAngle;
  final bool motorRunning;
  final bool lightOn;
  final int intensity;
  final double selectedAngle;
  final double selectedSpeed;
  final bool busy;
  final String calibrationStatus;
  final bool healthOk;
  final MachineInfo? info;
  final String? lastRawResponse;
  final bool? positiveDirectionIsCW;

  bool get isVerified => phase == DiamondCamPhase.verified;

  DiamondCamUiState copyWith({
    DiamondCamPhase? phase,
    String? message,
    double? commandedAngle,
    bool? motorRunning,
    bool? lightOn,
    int? intensity,
    double? selectedAngle,
    double? selectedSpeed,
    bool? busy,
    String? calibrationStatus,
    bool? healthOk,
    MachineInfo? info,
    String? lastRawResponse,
    bool? positiveDirectionIsCW,
    bool clearMessage = false,
  }) {
    return DiamondCamUiState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      commandedAngle: commandedAngle ?? this.commandedAngle,
      motorRunning: motorRunning ?? this.motorRunning,
      lightOn: lightOn ?? this.lightOn,
      intensity: intensity ?? this.intensity,
      selectedAngle: selectedAngle ?? this.selectedAngle,
      selectedSpeed: selectedSpeed ?? this.selectedSpeed,
      busy: busy ?? this.busy,
      calibrationStatus: calibrationStatus ?? this.calibrationStatus,
      healthOk: healthOk ?? this.healthOk,
      info: info ?? this.info,
      lastRawResponse: lastRawResponse ?? this.lastRawResponse,
      positiveDirectionIsCW:
          positiveDirectionIsCW ?? this.positiveDirectionIsCW,
    );
  }
}

enum DiamondCamPhase {
  disconnected,
  connecting,
  reachable,
  verified,
  protocolMismatch,
  error,
  resetting,
}

String diamondCamPhaseLabel(DiamondCamPhase phase) {
  switch (phase) {
    case DiamondCamPhase.verified:
      return 'Protocol Verified';
    case DiamondCamPhase.reachable:
    case DiamondCamPhase.protocolMismatch:
      return 'ESP32 Reachable · Protocol Unverified';
    case DiamondCamPhase.connecting:
      return 'Connecting';
    case DiamondCamPhase.resetting:
      return 'Resetting';
    case DiamondCamPhase.error:
      return 'Error';
    case DiamondCamPhase.disconnected:
      return 'Disconnected';
  }
}

class DiamondCamStateNotifier extends StateNotifier<DiamondCamUiState> {
  DiamondCamStateNotifier(
    this._service, {
    DeviceConnectionManager? connectionManager,
  }) : _connectionManager = connectionManager,
       super(
         DiamondCamUiState(
           calibrationStatus: MachineCalibration.current.calibrationStatus,
         ),
       );

  final DiamondCamService _service;
  final DeviceConnectionManager? _connectionManager;

  Future<void> refreshStatus() async {
    state = state.copyWith(
      phase: DiamondCamPhase.connecting,
      busy: true,
      clearMessage: true,
    );
    final health = await _service.getHealth();
    if (!mounted) return;
    var info = await _service.info();
    if (!mounted) return;
    final result = await _service.getStatus();
    if (!mounted) return;
    _applyStatusResult(
      result,
      healthOk: health.ok || result.statusCode == 200,
      info: info.ok ? info.info : state.info,
      markBusyFalse: true,
    );
    _publishConnection();
  }

  void setSelectedAngle(double value) {
    state = state.copyWith(selectedAngle: value);
  }

  void setSelectedSpeed(double value) {
    state = state.copyWith(selectedSpeed: value);
  }

  void setIntensityPreview(int intensity) {
    state = state.copyWith(intensity: intensity.clamp(0, 100));
  }

  Future<String> rotateToSelected() async {
    final angle = state.selectedAngle;
    final result = await execute(
      () => _service.rotate(angle: angle, speed: state.selectedSpeed),
    );
    if (mounted && result.ok) {
      state = state.copyWith(commandedAngle: angle);
    }
    return result.message;
  }

  Future<String> continuousCw() => _run(
    () => _service.continuous(
      direction: DiamondCamProtocol.directionCw,
      speed: state.selectedSpeed,
    ),
  );

  Future<String> continuousCcw() => _run(
    () => _service.continuous(
      direction: DiamondCamProtocol.directionCcw,
      speed: state.selectedSpeed,
    ),
  );

  Future<String> stop() => _run(_service.stop);

  Future<String> setLight({required bool on, int? intensity}) async {
    final value =
        intensity ?? (on ? (state.intensity <= 0 ? 80 : state.intensity) : 0);
    final message = await _run(
      () => _service.setLight(state: on, intensity: value),
    );
    return message;
  }

  Future<String> setBrightness(int intensity) =>
      setLight(on: intensity > 0, intensity: intensity);

  Future<String> resetAndReconnect() async {
    state = state.copyWith(
      phase: DiamondCamPhase.resetting,
      busy: true,
      message: 'Reset command sent. Waiting for ESP32 restart…',
      motorRunning: false,
    );
    final reset = await _service.reset();
    if (!mounted) return reset.message;
    if (!reset.ok && reset.stage == MachineCommandStage.notSent) {
      state = state.copyWith(
        phase: DiamondCamPhase.error,
        message: reset.message,
        busy: false,
      );
      return reset.message;
    }
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return reset.message;
    await refreshStatus();
    return state.message ?? reset.message;
  }

  Future<String> _run(Future<DiamondCamResult> Function() action) async {
    final result = await execute(action);
    return result.message;
  }

  Future<DiamondCamResult> execute(
    Future<DiamondCamResult> Function() action,
  ) async {
    state = state.copyWith(busy: true, clearMessage: true);
    final result = await action();
    if (!mounted) return result;
    state = state.copyWith(
      busy: false,
      message: result.message,
      lastRawResponse: result.body,
    );
    _publishConnection();
    if (result.ok) {
      unawaited(_refreshQuiet());
    }
    return result;
  }

  Future<void> _refreshQuiet() async {
    final result = await _service.getStatus();
    if (!mounted) return;
    if (result.ok && result.status != null && result.status!.accepted) {
      _applyStatusResult(
        result,
        healthOk: state.healthOk,
        info: state.info,
        markBusyFalse: false,
        preserveMessage: true,
      );
    }
  }

  void _applyStatusResult(
    DiamondCamResult result, {
    required bool markBusyFalse,
    bool healthOk = false,
    MachineInfo? info,
    bool preserveMessage = false,
  }) {
    final cal =
        info?.calibrationLabel ?? MachineCalibration.current.calibrationStatus;
    if (!result.ok || result.status == null || !result.status!.accepted) {
      final reachable = result.statusCode == 200;
      state = state.copyWith(
        phase: reachable
            ? DiamondCamPhase.protocolMismatch
            : DiamondCamPhase.error,
        message: result.message,
        busy: markBusyFalse ? false : state.busy,
        healthOk: healthOk,
        info: info,
        lastRawResponse: result.body,
        calibrationStatus: cal,
        positiveDirectionIsCW: info?.positiveDirectionIsCW,
      );
      _publishConnection();
      return;
    }
    final status = result.status!;
    state = state.copyWith(
      phase: DiamondCamPhase.verified,
      message: preserveMessage ? state.message : result.message,
      commandedAngle: status.rotation?.toDouble() ?? state.commandedAngle,
      motorRunning: status.motorRunning ?? false,
      lightOn:
          status.light == true ||
          status.light == 1 ||
          '${status.light}'.toLowerCase() == 'on',
      intensity: status.intensity?.round() ?? state.intensity,
      busy: markBusyFalse ? false : state.busy,
      healthOk: healthOk,
      info: info,
      lastRawResponse: result.body,
      calibrationStatus: cal,
      positiveDirectionIsCW: info?.positiveDirectionIsCW,
    );
    _publishConnection();
  }

  void _publishConnection() {
    final manager = _connectionManager;
    if (manager == null) {
      return;
    }
    manager.updateVerifiedState(deviceConnectionFromDiamondCam(state));
  }
}

DeviceConnectionState deviceConnectionFromDiamondCam(
  DiamondCamUiState diamond,
) {
  const name = 'ESP32 Machine';
  switch (diamond.phase) {
    case DiamondCamPhase.verified:
      return DeviceConnectionState.connected(
        name,
        0,
        lastVerifiedAt: DateTime.now(),
      );
    case DiamondCamPhase.reachable:
    case DiamondCamPhase.protocolMismatch:
      return DeviceConnectionState.connectedUnverified(
        name,
        message: diamond.message ?? 'ESP32 reachable. Protocol unverified.',
      );
    case DiamondCamPhase.connecting:
      return DeviceConnectionState.connecting(name);
    case DiamondCamPhase.resetting:
      return DeviceConnectionState.reconnecting(name);
    case DiamondCamPhase.error:
      return DeviceConnectionState.error(
        diamond.message ?? 'Machine error',
        deviceName: name,
      );
    case DiamondCamPhase.disconnected:
      return DeviceConnectionState.disconnected(name);
  }
}

DeviceConnectionState resolveMachineConnection(
  DiamondCamUiState diamond, [
  DeviceConnectionState? managed,
]) {
  if (diamond.phase != DiamondCamPhase.disconnected) {
    return deviceConnectionFromDiamondCam(diamond);
  }
  return managed ?? deviceConnectionFromDiamondCam(diamond);
}

final diamondCamStateProvider =
    StateNotifierProvider<DiamondCamStateNotifier, DiamondCamUiState>((ref) {
      return DiamondCamStateNotifier(
        ref.read(diamondCamServiceProvider),
        connectionManager: ref.read(deviceConnectionManagerProvider),
      );
    });

final machineConnectionProvider = Provider<DeviceConnectionState>((ref) {
  final diamond = ref.watch(diamondCamStateProvider);
  final managed = ref.watch(deviceConnectionStateProvider).valueOrNull;
  return resolveMachineConnection(diamond, managed);
});
