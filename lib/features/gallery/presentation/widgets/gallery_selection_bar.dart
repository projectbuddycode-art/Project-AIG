import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class GallerySelectionBar extends StatelessWidget {
  const GallerySelectionBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onExport,
    required this.onFavorite,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.l),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.elevated,
      ),
      child: Row(
        children: [
          Expanded(child: Text('$selectedCount selected', style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700))),
          IconButton(onPressed: onFavorite, icon: const Icon(Icons.favorite_outline_rounded)),
          IconButton(onPressed: onExport, icon: const Icon(Icons.upload_file_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }
}
