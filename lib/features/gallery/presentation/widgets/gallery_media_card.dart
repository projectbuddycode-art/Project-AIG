import 'dart:io';

import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'gallery_status_badge.dart';

class GalleryMediaCard extends StatelessWidget {
  const GalleryMediaCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppAnimation.standard,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: selected ? AppColors.accentGold : AppColors.border),
          boxShadow: AppShadow.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
                      child: _GalleryThumb(item: item),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.s,
                    left: AppSpacing.s,
                    child: GalleryStatusBadge(label: item.mediaType.label, color: AppColors.accentGoldDark, icon: item.mediaType == MediaType.video ? Icons.videocam : Icons.photo_camera),
                  ),
                  if (item.isFavorite)
                    const Positioned(
                      top: AppSpacing.s,
                      right: AppSpacing.s,
                      child: Icon(Icons.favorite_rounded, color: AppColors.accentGoldDark, size: 18),
                    ),
                  Positioned(
                    bottom: AppSpacing.s,
                    right: AppSpacing.s,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        metadata.resolutionWidth != null && metadata.resolutionHeight != null ? '${metadata.resolutionWidth}x${metadata.resolutionHeight}' : '—',
                        style: AppTypography.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                      if (selected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.accentGoldDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_formatDate(item.createdAt), style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  if ((metadata.presetUsed ?? '').isNotEmpty)
                    Text(metadata.presetUsed!, style: AppTypography.label.copyWith(color: AppColors.textSecondary, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (item.metadata.aiTags.isNotEmpty)
                        GalleryStatusBadge(label: 'Processing', color: AppColors.accentGoldDark, icon: Icons.auto_awesome),
                      if (metadata.fileSizeBytes != null)
                        GalleryStatusBadge(label: 'Export', color: AppColors.accentGoldDark, icon: Icons.upload_file),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final path = item.thumbnailPath;
    if (path != null && path.isNotEmpty && !path.startsWith('content://')) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.secondaryBackground,
      child: Center(
        child: Icon(
          item.mediaType == MediaType.video ? Icons.videocam_outlined : Icons.image_outlined,
          size: 48,
          color: AppColors.accentGoldDark,
        ),
      ),
    );
  }
}
