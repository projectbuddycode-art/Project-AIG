import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class PresetQuickActions extends StatelessWidget {
  const PresetQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadow.soft,
      ),
      child: Text(
        'Use the preset cards to apply, duplicate, or delete a preset from the studio workflow.',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
