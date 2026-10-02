import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class GallerySummaryBar extends StatelessWidget {
  const GallerySummaryBar({
    super.key,
    required this.totalMedia,
    required this.photoCount,
    required this.videoCount,
    required this.selectedCount,
    required this.processingQueue,
    required this.exportQueue,
  });

  final int totalMedia;
  final int photoCount;
  final int videoCount;
  final int selectedCount;
  final int processingQueue;
  final int exportQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.soft,
      ),
      child: Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        children: [
          _chip('Media', '$totalMedia'),
          _chip('Photos', '$photoCount'),
          _chip('Videos', '$videoCount'),
          _chip('Selected', '$selectedCount'),
          _chip('Processing', '$processingQueue'),
          _chip('Export', '$exportQueue'),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTypography.subtitle.copyWith(color: AppColors.accentGoldDark, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTypography.label),
        ],
      ),
    );
  }
}
