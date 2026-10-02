import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class PresetCategories extends StatelessWidget {
  const PresetCategories({
    super.key,
    required this.categories,
    required this.active,
    required this.onSelected,
  });

  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final c = categories[index];
          final selected = c == active;
          return GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: AppAnimation.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentGoldLight : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.accentGold : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  c,
                  style: AppTypography.label.copyWith(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.s),
        itemCount: categories.length,
      ),
    );
  }
}
