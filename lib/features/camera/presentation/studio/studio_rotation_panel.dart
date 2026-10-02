import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'studio_panel_card.dart';
import 'studio_section_title.dart';
import 'studio_action_button.dart';

/// Studio rotation controls mapped to DiamondCam firmware.
/// HOME is unavailable — no sensor / no /home endpoint.
class StudioRotationPanel extends StatelessWidget {
  const StudioRotationPanel({
    super.key,
    required this.onLeft,
    required this.onRight,
    required this.onStop,
    required this.onContinuousCw,
    required this.onContinuousCcw,
    required this.onSpeedChanged,
    required this.onDegreesChanged,
    required this.speed,
    required this.degrees,
    this.busy = false,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onStop;
  final VoidCallback onContinuousCw;
  final VoidCallback onContinuousCcw;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onDegreesChanged;
  final double speed;
  final double degrees;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return StudioPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioSectionTitle(title: 'Rotation'),
          const SizedBox(height: AppSpacing.s),
          Text(
            'LEFT/RIGHT adjust commanded angle 0–180. Cont. CW/CCW use /rotate/continuous. '
            'Physical direction unconfirmed. Home sensor not installed.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              StudioActionButton(
                label: 'Left',
                icon: Icons.rotate_left,
                primary: false,
                onPressed: busy ? null : onLeft,
              ),
              StudioActionButton(
                label: 'Right',
                icon: Icons.rotate_right,
                primary: false,
                onPressed: busy ? null : onRight,
              ),
              StudioActionButton(
                label: 'Cont. CW',
                icon: Icons.autorenew,
                primary: false,
                onPressed: busy ? null : onContinuousCw,
              ),
              StudioActionButton(
                label: 'Cont. CCW',
                icon: Icons.sync,
                primary: false,
                onPressed: busy ? null : onContinuousCcw,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Opacity(
            opacity: 0.5,
            child: StudioActionButton(
              label: 'Home sensor not installed',
              icon: Icons.home_outlined,
              primary: false,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Home sensor not installed')),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          StudioActionButton(
            label: 'Stop',
            icon: Icons.stop_circle_outlined,
            primary: false,
            onPressed: busy ? null : onStop,
          ),
          const SizedBox(height: AppSpacing.m),
          Text('Speed', style: AppTypography.subtitle),
          Slider(
            value: speed,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: busy ? null : onSpeedChanged,
          ),
          Text(
            'Firmware speed ${speed.round()} (1–100)',
            style: AppTypography.subtitle,
          ),
          Text(
            'Step ${degrees.round()}° (commanded angle)',
            style: AppTypography.subtitle,
          ),
          Slider(
            value: degrees,
            min: 15,
            max: 180,
            divisions: 11,
            onChanged: busy ? null : onDegreesChanged,
          ),
        ],
      ),
    );
  }
}
