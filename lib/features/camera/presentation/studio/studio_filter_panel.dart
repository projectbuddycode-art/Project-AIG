import 'package:flutter/material.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/presentation/studio/studio_panel_card.dart';
import 'package:aig/features/camera/presentation/studio/studio_section_title.dart';

class StudioFilterPanel extends StatelessWidget {
  const StudioFilterPanel({
    super.key,
    required this.look,
    required this.strength,
    required this.onLookChanged,
    required this.onStrengthChanged,
  });

  final JewelryProcessingLook look;
  final int strength;
  final ValueChanged<JewelryProcessingLook> onLookChanged;
  final ValueChanged<int> onStrengthChanged;

  @override
  Widget build(BuildContext context) {
    return StudioPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioSectionTitle(title: 'Jewelry filters'),
          const SizedBox(height: AppSpacing.s),
          Text(jewelryProcessingLookLabel(look), style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final option in studioFilterLooks)
                ChoiceChip(
                  label: Text(jewelryProcessingLookLabel(option)),
                  selected: option == look,
                  onSelected: (_) => onLookChanged(option),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text('Filter strength $strength%', style: AppTypography.subtitle),
          Slider(
            value: strength.clamp(0, 100).toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$strength%',
            onChanged: look == JewelryProcessingLook.original
                ? null
                : (value) => onStrengthChanged(value.round()),
          ),
          Text(
            'Preview tint matches the export grade. This is color correction, not background cut-out.',
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
