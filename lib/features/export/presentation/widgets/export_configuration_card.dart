import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/export/providers/export_providers.dart';

class ExportConfigurationCard extends ConsumerStatefulWidget {
  const ExportConfigurationCard({super.key});

  @override
  ConsumerState<ExportConfigurationCard> createState() =>
      _ExportConfigurationCardState();
}

class _ExportConfigurationCardState
    extends ConsumerState<ExportConfigurationCard> {
  String _imageFormat = 'JPEG';
  String _videoFormat = 'MP4';
  String _resolution = 'Original';
  String _quality = 'High';
  String _watermark = 'None';
  String _destination = 'Device Gallery';

  @override
  void initState() {
    super.initState();
    final queue = ref.read(exportQueueProvider);
    final jobs = queue.pendingJobs;
    if (jobs.any((j) => (j.metadata['mediaType'] ?? '') == 'video')) {
      _videoFormat = 'MP4';
      _imageFormat = 'JPEG';
    } else if (jobs.any((j) => (j.metadata['mediaType'] ?? '') == 'photo')) {
      _imageFormat = 'JPEG';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Configuration',
            style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              _optionGroup(
                'Image',
                ['JPEG', 'PNG', 'TIFF', 'WEBP'],
                _imageFormat,
                (v) => setState(() => _imageFormat = v),
              ),
              _optionGroup(
                'Video',
                ['MP4', 'MOV'],
                _videoFormat,
                (v) => setState(() => _videoFormat = v),
              ),
              _optionGroup(
                'Resolution',
                ['Original', '4K', '2K', '1080P', '720P'],
                _resolution,
                (v) => setState(() => _resolution = v),
              ),
              _optionGroup(
                'Quality',
                ['Maximum', 'Ultra', 'High'],
                _quality,
                (v) => setState(() => _quality = v),
              ),
              _optionGroup(
                'Watermark',
                ['None', 'Logo', 'Text'],
                _watermark,
                (v) => setState(() => _watermark = v),
              ),
              _optionGroup(
                'Destination',
                ['Device Gallery', 'Local Folder'],
                _destination,
                (v) => setState(() => _destination = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionGroup(
    String title,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: options.map((o) {
              final isSelected = o == selected;
              return ChoiceChip(
                label: Text(o),
                selected: isSelected,
                onSelected: (_) => onSelected(o),
                selectedColor: AppColors.accentGoldLight,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.accentGold : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
