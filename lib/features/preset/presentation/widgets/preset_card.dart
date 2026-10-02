import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class PresetCard extends StatelessWidget {
  const PresetCard({super.key, required this.preset, required this.category});

  final CameraPreset preset;
  final String category;

  @override
  Widget build(BuildContext context) {
    final isActive =
        preset.id.contains('diamond') || preset.id.contains('luxury');
    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accentGoldLight.withValues(alpha: 0.22)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isActive ? AppColors.accentGold : AppColors.border,
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'preset-hero-${preset.id}',
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                color: AppColors.secondaryBackground,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      preset.isVideoPreset ? Icons.videocam : Icons.photo,
                      color: AppColors.accentGoldDark,
                      size: 32,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadow.soft,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: AppColors.accentGoldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.name,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (preset.isVideoPreset)
                      const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.accentGoldDark,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _buildChipIf(preset.processingPipeline, 'raw', 'RAW'),
                    _buildChipIf(preset.processingPipeline, 'hdr', 'HDR'),
                    if (preset.rotationConfig.autoRotate ||
                        preset.rotationConfig.steps >= 36)
                      _statusChip('360°'),
                    if (preset.processingPipeline.any(
                      (p) => p.toLowerCase().contains('ai'),
                    ))
                      _statusChip('AI'),
                    if (preset.isVideoPreset) _statusChip('Reel'),
                    if (preset.id.toLowerCase().contains('catalogue') ||
                        preset.exportDefaults.resolution.toLowerCase().contains(
                          '4k',
                        ))
                      _statusChip('Catalog'),
                  ].where((w) => w != null).cast<Widget>().toList(),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _metaText('ISO ${preset.cameraConfig.iso}'),
                    _metaText('f/${preset.cameraConfig.aperture}'),
                    _metaText(
                      '${(preset.lightingConfig.brightness * 100).round()}%',
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Export: ${preset.exportDefaults.resolution} • Steps: ${preset.rotationConfig.steps}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaText(String text) {
    return Text(
      text,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildChipIf(List<String> pipeline, String key, String label) {
    final found = pipeline.any((p) => p.toLowerCase().contains(key));
    return found ? _statusChip(label) : null;
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
