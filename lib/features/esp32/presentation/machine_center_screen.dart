import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/core/widgets/premium_button.dart';
import 'package:aig/core/widgets/primary_card.dart';
import 'package:aig/core/widgets/status_chip.dart';
import 'package:aig/features/esp32/models/machine_calibration.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';
import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MachineCenterScreen extends ConsumerStatefulWidget {
  const MachineCenterScreen({super.key});

  @override
  ConsumerState<MachineCenterScreen> createState() => _MachineCenterScreenState();
}

class _MachineCenterScreenState extends ConsumerState<MachineCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(diamondCamStateProvider.notifier).refreshStatus();
    });
  }

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diamondCamStateProvider);
    final notifier = ref.read(diamondCamStateProvider.notifier);
    final calibration = MachineCalibration.current;
    final info = state.info;

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('DiamondCam', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            onPressed: state.busy ? null : () => notifier.refreshStatus(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          PrimaryCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DiamondCam', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    StatusChip(
                      label: state.healthOk ? 'ESP32 Reachable' : diamondCamPhaseLabel(state.phase),
                      icon: Icons.wifi,
                      backgroundColor: state.healthOk || state.phase == DiamondCamPhase.verified
                          ? AppColors.accentGoldLight
                          : AppColors.secondaryBackground,
                    ),
                    StatusChip(
                      label: state.isVerified ? 'Protocol Verified' : 'Protocol Unverified',
                      icon: state.isVerified ? Icons.check_circle_outline : Icons.warning_amber,
                      backgroundColor: state.isVerified
                          ? AppColors.accentGoldLight
                          : Colors.orange.shade100,
                    ),
                    _Badge(label: 'Calibration', value: state.calibrationStatus),
                    _Badge(label: 'Commanded Angle', value: '${state.commandedAngle.round()}°'),
                    _Badge(
                      label: 'Motor',
                      value: state.isVerified
                          ? (state.motorRunning ? 'Running' : 'Idle')
                          : 'Unknown',
                    ),
                    _Badge(label: 'Physical Position', value: 'Unavailable (no encoder)'),
                    const _Badge(label: 'Physical movement', value: 'Unverified'),
                  ],
                ),
                if (state.message != null && state.message!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    state.message!,
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          PrimaryCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine info', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.m),
                _InfoRow(label: 'Machine ID', value: info?.machineIdLabel ?? 'Unavailable'),
                _InfoRow(label: 'Firmware', value: info?.firmwareLabel ?? 'Unavailable'),
                _InfoRow(
                  label: 'Motor step angle',
                  value: info?.motorStepAngle != null ? '${info!.motorStepAngle}°' : '1.8° (NEMA17 nameplate)',
                ),
                _InfoRow(
                  label: 'Microsteps',
                  value: info?.microsteps != null
                      ? '${info!.microsteps} (firmware reported)'
                      : '16 (DM542 DIP contract, /info not loaded)',
                ),
                _InfoRow(
                  label: 'Pulses/revolution',
                  value: info?.pulsesPerRevolution != null
                      ? '${info!.pulsesPerRevolution} (firmware reported)'
                      : '3200 (DM542 DIP contract, /info not loaded)',
                ),
                _InfoRow(
                  label: 'Pulses/degree',
                  value: info?.pulsesPerDegree != null
                      ? '${info!.pulsesPerDegree} (firmware reported)'
                      : '8.888889 (DM542 DIP contract, /info not loaded)',
                ),
                _InfoRow(
                  label: 'Gear ratio',
                  value: info?.gearRatio != null ? '${info!.gearRatio} (direct drive)' : '1.0 (direct drive)',
                ),
                _InfoRow(label: 'HOME sensor', value: info?.homeLabel ?? 'Not installed'),
                _InfoRow(label: 'Limit sensor', value: info?.limitLabel ?? 'Not installed'),
                _InfoRow(label: 'Direction', value: info?.directionLabel ?? 'Unconfirmed'),
                _InfoRow(label: 'Calibration', value: info?.calibrationLabel ?? 'Unconfirmed'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          PrimaryCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rotation', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    Expanded(
                      child: PremiumButton(
                        label: 'CCW',
                        onPressed: state.busy
                            ? null
                            : () async => _toast(await notifier.continuousCcw()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: PremiumButton(
                        label: 'STOP',
                        onPressed: state.busy ? null : () async => _toast(await notifier.stop()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: PremiumButton(
                        label: 'CW',
                        onPressed: state.busy
                            ? null
                            : () async => _toast(await notifier.continuousCw()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                Text('Angle: ${state.selectedAngle.round()}°', style: AppTypography.subtitle),
                Slider(
                  value: state.selectedAngle,
                  min: calibration.minAngle,
                  max: calibration.maxAngle,
                  divisions: 36,
                  onChanged: state.busy ? null : notifier.setSelectedAngle,
                ),
                Text('Speed: ${state.selectedSpeed.round()}', style: AppTypography.subtitle),
                Slider(
                  value: state.selectedSpeed,
                  min: 1,
                  max: calibration.maxSpeed,
                  divisions: 99,
                  onChanged: state.busy ? null : notifier.setSelectedSpeed,
                ),
                PremiumButton(
                  label: 'Move to angle',
                  onPressed: state.busy ? null : () async => _toast(await notifier.rotateToSelected()),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'App CW sends direction=cw. App CCW sends direction=ccw. '
                  'Physical CW mapping is ${info?.directionLabel ?? 'Unconfirmed'}. '
                  'Stop is a software stop, not an emergency cut-off.',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          PrimaryCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lighting (GPIO 33 only)', style: AppTypography.headline),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(state.lightOn ? 'Light: ON' : 'Light: OFF'),
                  value: state.lightOn,
                  onChanged: state.busy
                      ? null
                      : (value) async => _toast(await notifier.setLight(on: value)),
                ),
                Text('Brightness: ${state.intensity}', style: AppTypography.subtitle),
                Slider(
                  value: state.intensity.toDouble().clamp(0, 100),
                  min: 0,
                  max: calibration.maxLightIntensity.toDouble(),
                  divisions: 20,
                  onChanged: state.busy ? null : (value) => notifier.setIntensityPreview(value.round()),
                  onChangeEnd: state.busy
                      ? null
                      : (value) async => _toast(await notifier.setBrightness(value.round())),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          PrimaryCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System', style: AppTypography.headline),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    const Expanded(
                      child: PremiumButton(
                        label: 'HOME',
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: PremiumButton(
                        label: 'RESET',
                        onPressed: state.busy
                            ? null
                            : () async => _toast(await notifier.resetAndReconnect()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Home sensor not installed. There is no /home endpoint.',
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Connect phone Wi-Fi to ${MachineEndpointConfig.wifiSsid}, then refresh. '
                  'Target ${MachineEndpointConfig.current.originForLog}',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.subtitle),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.body, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
