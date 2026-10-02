import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class PresetEmptyState extends StatelessWidget {
  const PresetEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: AppShadow.soft,
              ),
              child: const Center(
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: AppColors.accentGoldDark,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Refine your capture workflow',
              style: AppTypography.headline.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Create polished presets for camera, lighting, rotation, and export so every session feels repeatable and premium.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create Preset'),
            ),
          ],
        ),
      ),
    );
  }
}
