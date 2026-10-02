import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class StudioMetricChip extends StatelessWidget {
  const StudioMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.active = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accentGoldLight
            : AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.accentGoldDark),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppTypography.subtitle.copyWith(
              color: AppColors.accentGoldDark,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
