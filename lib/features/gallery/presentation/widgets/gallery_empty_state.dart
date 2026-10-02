import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class GalleryEmptyState extends StatelessWidget {
  const GalleryEmptyState({super.key, required this.onOpenCameraStudio});

  final VoidCallback onOpenCameraStudio;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadow.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentGoldLight),
                child: const Center(child: Icon(Icons.camera_alt_outlined, size: 44, color: AppColors.accentGoldDark)),
              ),
              const SizedBox(height: AppSpacing.l),
              Text('No captures yet', style: AppTypography.headline.copyWith(fontSize: 24)),
              const SizedBox(height: AppSpacing.s),
              Text('Your studio sessions will appear here once you begin capturing.', style: AppTypography.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.l),
              FilledButton.icon(
                onPressed: onOpenCameraStudio,
                icon: const Icon(Icons.camera_enhance_outlined),
                label: const Text('Open Camera Studio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
