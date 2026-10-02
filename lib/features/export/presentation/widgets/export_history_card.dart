import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/export/providers/export_providers.dart';

class ExportHistoryCard extends ConsumerWidget {
  const ExportHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(exportQueueProvider);
    final history = queue.pendingJobs;

    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadow.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export History', style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s),
          if (history.isEmpty)
            Text(
              'No export activity yet.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            )
          else
            Column(
              children: history.map((job) {
                return ListTile(
                  leading: Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.upload_file_outlined)),
                  title: Text(job.id, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${job.task.configuration.format.name} • ${job.state.name}', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                  trailing: Text('${job.progress.percent.toStringAsFixed(0)}%', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
