import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:aig/features/camera/presentation/studio/studio_panel_card.dart';
import 'package:aig/features/camera/presentation/studio/studio_metric_chip.dart';

class StudioTopBar extends StatelessWidget {
  const StudioTopBar({
    super.key,
    required this.presetName,
    required this.connected,
    required this.onBack,
    required this.onSettings,
  });

  final String presetName;
  final bool connected;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: StudioPanelCard(
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diamond Luxury',
                    style: AppTypography.subtitle.copyWith(
                      color: AppColors.accentGoldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        presetName,
                        style: AppTypography.headline.copyWith(fontSize: 18),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            StudioMetricChip(
              label: 'Connected',
              value: connected ? '🟢' : '⛔',
              icon: connected
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
            const SizedBox(width: AppSpacing.s),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
