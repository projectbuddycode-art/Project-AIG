import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/core/widgets/primary_card.dart';
import 'package:aig/core/widgets/section_header.dart';
import 'package:aig/core/widgets/status_chip.dart';
import 'package:aig/features/subscription/models/subscription_plan.dart';
import 'package:aig/features/subscription/providers/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionCenterScreen extends ConsumerWidget {
  const SubscriptionCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(subscriptionStateNotifierProvider);
    final state = notifier.state;
    final plan = state.plan;
    final usage = state.usage;
    final renewalDate =
        plan.expiresAt ?? DateTime.now().add(const Duration(days: 30));

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Subscription Center',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimaryCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldLight,
                            borderRadius: BorderRadius.circular(
                              AppRadius.large,
                            ),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.accentGoldDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.l),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${plan.name} Plan',
                                style: AppTypography.headline,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              StatusChip(
                                label: _planStatusLabel(plan.status),
                                icon: plan.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_outlined,
                                backgroundColor: plan.isActive
                                    ? AppColors.success
                                    : AppColors.secondaryBackground,
                                foregroundColor: plan.isActive
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      'Next billing on ${renewalDate.month}/${renewalDate.day}/${renewalDate.year}',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.m,
                      children: [
                        _InfoPill(
                          label: 'Devices',
                          value: '${plan.maxDevices}',
                        ),
                        _InfoPill(
                          label: 'Storage',
                          value: '${plan.maxStorageMb} MB',
                        ),
                        _InfoPill(
                          label: 'Resolution',
                          value: plan.maxResolution.name.toUpperCase(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Usage Snapshot'),
              const SizedBox(height: AppSpacing.l),
              Wrap(
                spacing: AppSpacing.m,
                runSpacing: AppSpacing.m,
                children: [
                  _UsageMetric(
                    label: 'Exports',
                    value:
                        '${usage.exportsUsed}/${plan.monthlyExportLimit ?? 5}',
                  ),
                  _UsageMetric(
                    label: 'Storage',
                    value: '${usage.storageUsedMb} MB',
                  ),
                  _UsageMetric(
                    label: 'AI Credits',
                    value: '${usage.aiCreditsUsed}',
                  ),
                  _UsageMetric(
                    label: 'Video Minutes',
                    value: '${usage.videoMinutesUsed}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Included Premium Features',
                      style: AppTypography.headline,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    _FeatureRow(
                      label: 'Priority export queue',
                      icon: Icons.auto_awesome_outlined,
                    ),
                    _FeatureRow(
                      label: 'Extended device control',
                      icon: Icons.devices_outlined,
                    ),
                    _FeatureRow(
                      label: 'Studio-ready presets',
                      icon: Icons.star_outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.l),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentGoldDark,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'Your billing and subscription details are managed from your account settings or provider portal.',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadow.soft,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(value, style: AppTypography.headline.copyWith(fontSize: 18)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGoldDark),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(label, style: AppTypography.body)),
        ],
      ),
    );
  }
}

String _planStatusLabel(SubscriptionStatus status) {
  switch (status) {
    case SubscriptionStatus.active:
      return 'Active';
    case SubscriptionStatus.trial:
      return 'Trial';
    case SubscriptionStatus.expired:
      return 'Expired';
    case SubscriptionStatus.suspended:
      return 'Suspended';
    case SubscriptionStatus.cancelled:
      return 'Cancelled';
  }
}
