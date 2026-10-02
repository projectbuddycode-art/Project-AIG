import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/export/providers/export_providers.dart';
import 'package:aig/features/export/models/export_state.dart';

class ExportDashboard extends ConsumerWidget {
  const ExportDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(exportQueueProvider);
    final queued = queue.pendingJobs.length;
    final completed = queue.state == ExportState.completed ? 1 : 0; // presentation-only quick metrics

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadow.soft),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _metric('Pending', 'Jobs', queued),
          _metric('Completed', 'Jobs', completed),
        ],
      ),
    );
  }

  Widget _metric(String title, String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
        Text('$value', style: AppTypography.headline.copyWith(fontSize: 16)),
        Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
