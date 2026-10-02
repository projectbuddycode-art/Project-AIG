import 'package:flutter/material.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'studio_metric_chip.dart';

class StudioStatusBar extends StatelessWidget {
  const StudioStatusBar({
    super.key,
    required this.resolution,
    required this.fps,
    required this.machine,
    required this.lighting,
    required this.rotation,
    required this.storage,
    required this.exportQueue,
    required this.aiQueue,
    required this.connected,
  });

  final String resolution;
  final String fps;
  final String machine;
  final String lighting;
  final String rotation;
  final String storage;
  final String exportQueue;
  final String aiQueue;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          alignment: WrapAlignment.spaceBetween,
          children: [
            StudioMetricChip(
              label: 'Resolution',
              value: resolution,
              icon: Icons.high_quality,
            ),
            StudioMetricChip(label: 'FPS', value: fps, icon: Icons.speed),
            StudioMetricChip(
              label: 'Machine',
              value: machine,
              icon: Icons.desktop_windows,
            ),
            StudioMetricChip(
              label: 'Lighting',
              value: lighting,
              icon: Icons.wb_sunny,
            ),
            StudioMetricChip(
              label: 'Rotation',
              value: rotation,
              icon: Icons.sync,
            ),
            StudioMetricChip(
              label: 'Storage',
              value: storage,
              icon: Icons.sd_storage,
            ),
            StudioMetricChip(
              label: 'Export',
              value: exportQueue,
              icon: Icons.upload_file,
            ),
            StudioMetricChip(
              label: 'AI',
              value: aiQueue,
              icon: Icons.auto_fix_high,
            ),
            StudioMetricChip(
              label: 'Status',
              value: connected ? 'Connected' : 'Offline',
              icon: connected
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
