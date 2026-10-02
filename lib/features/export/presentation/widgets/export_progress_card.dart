import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/export/providers/export_providers.dart';

class ExportProgressCard extends ConsumerWidget {
  const ExportProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(exportQueueProvider);
    final active = queue.activeJob;
    if (active == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: AppAnimation.standard,
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: AppShadow.soft),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.photo)),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(active.id, style: AppTypography.label.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(value: active.progress.percent, color: AppColors.accentGold, backgroundColor: AppColors.surface.withValues(alpha: 0.6)),
            ]),
          ),
          const SizedBox(width: AppSpacing.s),
          Text('${(active.progress.percent * 100).round()}%', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
