import 'package:flutter/material.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'studio_panel_card.dart';
import 'studio_status_bar.dart';
import 'studio_capture_button.dart';
import 'studio_action_button.dart';
import 'studio_metric_chip.dart';

class StudioOverlay extends StatelessWidget {
  const StudioOverlay({
    super.key,
    required this.connected,
    required this.onBack,
    required this.onSettings,
    required this.onCapture,
    required this.onGallery,
    required this.onToggleMode,
    required this.onPreset,
    required this.onExport,
    required this.modeLabel,
    required this.presetLabel,
    required this.resolution,
    required this.fps,
    required this.machine,
    required this.recording,
    required this.captureEnabled,
    required this.lighting,
    required this.rotation,
    required this.storage,
    required this.exportQueue,
    required this.aiQueue,
    required this.rotationPanel,
    required this.lightingPanel,
    this.bottomInset = AppSpacing.m,
  });

  final bool connected;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onToggleMode;
  final String modeLabel;
  final String presetLabel;
  final VoidCallback onPreset;
  final VoidCallback onExport;

  final String resolution;
  final String fps;
  final String machine;
  final bool recording;
  final bool captureEnabled;
  final String lighting;
  final String rotation;
  final String storage;
  final String exportQueue;
  final String aiQueue;

  final Widget rotationPanel;
  final Widget lightingPanel;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: AppSpacing.m,
          left: AppSpacing.m,
          right: AppSpacing.m,
          child: StudioPanelCard(
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIG Studio',
                        style: AppTypography.subtitle.copyWith(
                          color: AppColors.accentGoldDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              presetLabel,
                              style: AppTypography.headline.copyWith(
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StudioMetricChip(
                  label: 'Status',
                  value: connected ? 'Ready' : 'Offline',
                  icon: connected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.m,
          right: AppSpacing.m,
          bottom: bottomInset + AppSpacing.l + 120,
          child: StudioStatusBar(
            resolution: resolution,
            fps: fps,
            machine: machine,
            lighting: lighting,
            rotation: rotation,
            storage: storage,
            exportQueue: exportQueue,
            aiQueue: aiQueue,
            connected: connected,
          ),
        ),
        Positioned(
          top: null,
          left: AppSpacing.m,
          bottom: bottomInset + AppSpacing.s + 192,
          child: rotationPanel,
        ),
        Positioned(
          top: null,
          right: AppSpacing.m,
          bottom: bottomInset + AppSpacing.s + 192,
          child: lightingPanel,
        ),
        Positioned(
          left: AppSpacing.s,
          right: AppSpacing.s,
          bottom: bottomInset,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final buttons = [
                StudioActionButton(
                  label: 'Gallery',
                  icon: Icons.photo_library_outlined,
                  primary: false,
                  onPressed: onGallery,
                ),
                StudioActionButton(
                  label: 'Mode',
                  icon: Icons.tune_outlined,
                  primary: false,
                  onPressed: onToggleMode,
                ),
                StudioCaptureButton(
                  onTap: onCapture,
                  recording: recording,
                  enabled: captureEnabled,
                ),
                StudioActionButton(
                  label: 'Preset',
                  icon: Icons.auto_awesome_outlined,
                  primary: false,
                  onPressed: onPreset,
                ),
                StudioActionButton(
                  label: 'Export',
                  icon: Icons.upload_file_outlined,
                  primary: false,
                  onPressed: onExport,
                ),
              ];

              if (compact) {
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: buttons,
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: buttons
                    .map(
                      (button) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: button,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
