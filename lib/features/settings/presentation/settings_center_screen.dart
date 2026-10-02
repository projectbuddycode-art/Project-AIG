import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/core/widgets/primary_card.dart';
import 'package:aig/core/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsCenterScreen extends StatelessWidget {
  const SettingsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_SettingsSectionData>[
      _SettingsSectionData(
        title: 'Account',
        icon: Icons.person_outline,
        description: 'Manage profile and sign-in details',
      ),
      _SettingsSectionData(
        title: 'Subscription',
        icon: Icons.workspace_premium_outlined,
        description: 'Review your current plan and usage',
      ),
      _SettingsSectionData(
        title: 'Camera Preferences',
        icon: Icons.camera_alt_outlined,
        description: 'Adjust capture defaults and framing',
      ),
      _SettingsSectionData(
        title: 'Machine Preferences',
        icon: Icons.precision_manufacturing_outlined,
        description: 'Tune hardware controls and diagnostics',
      ),
      _SettingsSectionData(
        title: 'Export Defaults',
        icon: Icons.upload_outlined,
        description: 'Set export formats and quality',
      ),
      _SettingsSectionData(
        title: 'Notifications',
        icon: Icons.notifications_none,
        description: 'Control updates and reminders',
      ),
      _SettingsSectionData(
        title: 'Language',
        icon: Icons.language_outlined,
        description: 'Choose your preferred language',
      ),
      _SettingsSectionData(
        title: 'Theme',
        icon: Icons.palette_outlined,
        description: 'Switch between light and dark studio themes',
      ),
      _SettingsSectionData(
        title: 'Privacy Policy',
        icon: Icons.privacy_tip_outlined,
        description: 'View privacy information',
      ),
      _SettingsSectionData(
        title: 'Terms & Conditions',
        icon: Icons.description_outlined,
        description: 'Read the terms of use',
      ),
      _SettingsSectionData(
        title: 'Help & Support',
        icon: Icons.support_agent_outlined,
        description: 'Contact support or view help',
      ),
      _SettingsSectionData(
        title: 'About AIG',
        icon: Icons.info_outline,
        description: 'Learn more about the app',
      ),
      _SettingsSectionData(
        title: 'Application Version',
        icon: Icons.apps_outlined,
        description: 'Current app build information',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Settings',
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.accentGoldLight,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.accentGoldDark,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Studio Preferences',
                            style: AppTypography.headline,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Fine-tune camera, machine, and export settings for a smoother workflow.',
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Studio Settings'),
              const SizedBox(height: AppSpacing.l),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, index) {
                  final item = sections[index];
                  return _SettingsTile(data: item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.data});

  final _SettingsSectionData data;

  void _handleTap(BuildContext context) {
    switch (data.title) {
      case 'Subscription':
        context.push(AppRoutePath.subscriptionCenter);
        break;
      case 'Camera Preferences':
        context.push(AppRoutePath.cameraStudio);
        break;
      case 'Machine Preferences':
        context.push(AppRoutePath.machineCenter);
        break;
      case 'Export Defaults':
        context.push(AppRoutePath.export);
        break;
      case 'Application Version':
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(data.title),
            content: const Text('AIG jewelry capture studio\nPackage: com.ai.gravure.aig'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
      case 'Help & Support':
      case 'About AIG':
      case 'Theme':
      case 'Privacy Policy':
      case 'Terms & Conditions':
      default:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(data.title),
            content: const Text(
              'This section is not included in the current client demo. Camera Studio, Machine Center, Gallery, and Export are the active product screens.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () => _handleTap(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(data.icon, color: AppColors.accentGoldDark, size: 22),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    data.description,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            const Icon(Icons.chevron_right, color: AppColors.icon),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionData {
  const _SettingsSectionData({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;
}
