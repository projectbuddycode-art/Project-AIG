import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'studio_panel_card.dart';

class StudioPresetSelector extends StatelessWidget {
  const StudioPresetSelector({
    super.key,
    required this.presets,
    required this.selectedPresetId,
    required this.onPresetSelected,
  });

  final List<CameraPreset> presets;
  final String selectedPresetId;
  final ValueChanged<String> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return StudioPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Presets', style: AppTypography.headline.copyWith(fontSize: 16)),
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.m,
            children: presets.map((preset) {
              final selected = preset.id == selectedPresetId;
              return GestureDetector(
                onTap: () => onPresetSelected(preset.id),
                child: AnimatedContainer(
                  duration: AppAnimation.standard,
                  width: 160,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentGoldLight
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(
                      color: selected ? AppColors.accentGold : AppColors.border,
                    ),
                    boxShadow: selected ? AppShadow.soft : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            preset.isVideoPreset
                                ? Icons.videocam_outlined
                                : Icons.camera_alt_outlined,
                            color: AppColors.accentGoldDark,
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              preset.name,
                              style: AppTypography.subtitle.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(preset.description, style: AppTypography.body),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        preset.advertisingPurpose,
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        preset.requiresMachine
                            ? 'Machine required · ${preset.captureDurationSeconds}s'
                            : 'Camera only · ${preset.captureDurationSeconds}s',
                        style: AppTypography.label,
                      ),
                    ],
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
