import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/export/providers/export_providers.dart';

class ExportQueueCard extends ConsumerWidget {
  const ExportQueueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(exportQueueProvider);
    final controller = ref.read(exportControllerProvider);
    final pending = queue.pendingJobs;

    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadow.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export Queue', style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.s),
          if (pending.isEmpty) ...[
            Text('No queued jobs', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ] else ...[
            Column(
              children: pending.map((job) {
                final progress = job.progress.percent;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Row(
                    children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.image))),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(job.id, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Preset: Studio Default • Destination: Device', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.xs),
                          LinearProgressIndicator(value: progress, color: AppColors.accentGold, backgroundColor: AppColors.surface.withValues(alpha: 0.6)),
                        ]),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(onPressed: () => controller.retry(job.id), icon: const Icon(Icons.refresh)),
                      IconButton(onPressed: () => controller.cancel(job.id), icon: const Icon(Icons.cancel_outlined)),
                    ],
                  ),
                );
              }).toList(),
            )
          ]
        ],
      ),
    );
  }
}
