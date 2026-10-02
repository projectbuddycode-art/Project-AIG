import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class GallerySearchBar extends StatelessWidget {
  const GallerySearchBar({super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by filename, preset, date...',
          hintStyle: AppTypography.subtitle.copyWith(color: AppColors.textMuted),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentGoldDark),
        ),
      ),
    );
  }
}
