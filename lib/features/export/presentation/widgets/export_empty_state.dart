import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class ExportEmptyState extends StatelessWidget {
  const ExportEmptyState({super.key, required this.onOpenStudio, required this.onOpenGallery});

  final VoidCallback onOpenStudio;
  final VoidCallback onOpenGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 160, height: 160, decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(AppRadius.large), boxShadow: AppShadow.soft), child: const Center(child: Icon(Icons.upload_outlined, size: 64, color: AppColors.accentGoldDark))),
            const SizedBox(height: AppSpacing.l),
            Text('No Exports Yet', style: AppTypography.headline.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.s),
            Text('Capture media from Camera Studio or Gallery to begin exporting.', style: AppTypography.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.m),
            FilledButton(onPressed: onOpenStudio, child: const Text('Open Camera Studio')),
            const SizedBox(height: AppSpacing.s),
            OutlinedButton(onPressed: onOpenGallery, child: const Text('Open Gallery')),
          ],
        ),
      ),
    );
  }
}
