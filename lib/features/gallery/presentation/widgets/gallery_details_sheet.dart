import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_type.dart';

class GalleryDetailsSheet extends StatelessWidget {
  const GalleryDetailsSheet({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
    required this.onExport,
    required this.onDelete,
    required this.onClose,
  });

  final MediaItem item;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.title, style: AppTypography.headline.copyWith(fontSize: 20))),
                IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: Icon(item.mediaType == MediaType.video ? Icons.videocam : Icons.image_outlined, size: 56, color: AppColors.accentGoldDark)),
            ),
            const SizedBox(height: AppSpacing.m),
            _row('Media Type', item.mediaType.label),
            _row('Capture Date', '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
            _row('Resolution', metadata.resolutionWidth != null && metadata.resolutionHeight != null ? '${metadata.resolutionWidth}x${metadata.resolutionHeight}' : '—'),
            _row('Preset Used', metadata.presetUsed ?? '—'),
            _row('Capture Mode', metadata.cameraSettings ?? 'Standard'),
            _row('Processing Status', metadata.aiTags.isNotEmpty ? 'Processing' : 'Ready'),
            _row('Export Status', metadata.fileSizeBytes != null ? 'Queued' : 'Ready'),
            _row('File Size', metadata.fileSizeBytes != null ? '${(metadata.fileSizeBytes! / 1024).round()} KB' : '—'),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                FilledButton.icon(onPressed: onFavoriteToggle, icon: const Icon(Icons.favorite_outline), label: const Text('Favorite')),
                FilledButton.icon(onPressed: onExport, icon: const Icon(Icons.upload_file_outlined), label: const Text('Export')),
                OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.subtitle),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
