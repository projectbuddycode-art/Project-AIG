import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconBackground = AppColors.accentGoldLight,
    this.iconColor = AppColors.accentGoldDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(value, style: AppTypography.headline.copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.subtitle.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
