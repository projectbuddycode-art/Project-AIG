import 'package:flutter/material.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/presentation/studio/studio_panel_card.dart';
import 'package:aig/features/camera/presentation/studio/studio_section_title.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';

/// Single GPIO 33 channel. Never invents extra physical lights.
class StudioLightingPanel extends StatelessWidget {
  const StudioLightingPanel({
    super.key,
    required this.machinePhase,
    required this.firmwareLightOn,
    required this.firmwareIntensity,
    required this.requestedOn,
    required this.requestedIntensity,
    required this.busy,
    required this.commandMessage,
    required this.onMasterChanged,
    required this.onIntensityChanged,
  });

  final DiamondCamPhase machinePhase;
  final bool firmwareLightOn;
  final int firmwareIntensity;
  final bool requestedOn;
  final int requestedIntensity;
  final bool busy;
  final String? commandMessage;
  final ValueChanged<bool> onMasterChanged;
  final ValueChanged<int> onIntensityChanged;

  bool get _verified => machinePhase == DiamondCamPhase.verified;

  @override
  Widget build(BuildContext context) {
    final status = !_verified
        ? 'Machine disconnected — lighting is not sent to GPIO 33'
        : busy
        ? 'Sending light command…'
        : firmwareLightOn
        ? 'Firmware reports ON at $firmwareIntensity%'
        : 'Firmware reports OFF';
    return StudioPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioSectionTitle(title: 'Lighting'),
          const SizedBox(height: AppSpacing.s),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Master light'),
            subtitle: Text(
              _verified ? (requestedOn ? 'On' : 'Off') : 'Unavailable',
            ),
            value: _verified ? requestedOn : false,
            onChanged: (!_verified || busy) ? null : onMasterChanged,
          ),
          Text('Intensity $requestedIntensity%', style: AppTypography.subtitle),
          Slider(
            value: requestedIntensity.clamp(0, 100).toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$requestedIntensity%',
            onChanged: (!_verified || busy || !requestedOn)
                ? null
                : (value) => onIntensityChanged(value.round()),
          ),
          Text(
            status,
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          if (commandMessage != null && commandMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              commandMessage!,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          Text(
            'One lighting channel (GPIO 33). Top, side, back, and sparkle lights are not on this machine.',
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
