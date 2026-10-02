import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/core/widgets/common_bottom_navigation.dart';
import 'package:aig/core/widgets/icon_badge.dart';
import 'package:aig/core/widgets/metric_tile.dart';
import 'package:aig/core/widgets/outline_button.dart';
import 'package:aig/core/widgets/primary_card.dart';
import 'package:go_router/go_router.dart';
import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/widgets/premium_divider.dart';
import 'package:aig/core/widgets/premium_button.dart';
import 'package:aig/core/widgets/section_header.dart';
import 'package:aig/core/widgets/status_chip.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/providers/machine_controllers_providers.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'package:aig/features/gallery/providers/gallery_providers.dart';
import 'package:aig/features/subscription/providers/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  late final MachineStatusController _machineStatus;

  @override
  void initState() {
    super.initState();
    _machineStatus = ref.read(machineControllerProvider).status;
    debugPrint('[AIG_STARTUP] Dashboard mounted');
  }

  @override
  void dispose() {
    _machineStatus.stopDailyDiagnostics();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final machine = ref.read(machineControllerProvider);
    final connectionState = ref.watch(machineConnectionProvider);
    if (connectionState.status == ConnectionStatus.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _machineStatus.beginDailyDiagnostics();
      });
    }
    final subscriptionNotifier = ref.watch(subscriptionStateNotifierProvider);
    final planName = subscriptionNotifier.state.plan.name;
    final renewalDate =
        subscriptionNotifier.state.plan.expiresAt ??
        DateTime.now().add(const Duration(days: 30));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.m),
            _DashboardAppBar(),
            const SizedBox(height: AppSpacing.l),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeCard(planName: planName),
                    const SizedBox(height: AppSpacing.xxl),
                    _MachineStatusCard(
                      machine: machine,
                      connectionState: connectionState,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const _QuickActionsSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    const _RecentCapturesSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    _SubscriptionCard(
                      planName: planName,
                      renewalDate: renewalDate,
                    ),
                    const SizedBox(height: AppSpacing.xxl + AppSpacing.m),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 1:
              GoRouter.of(context).push(AppRoutePath.cameraStudio);
              break;
            case 2:
              GoRouter.of(context).push(AppRoutePath.gallery);
              break;
            case 3:
              GoRouter.of(context).push(AppRoutePath.presetStudio);
              break;
            case 4:
              GoRouter.of(context).push(AppRoutePath.settingsCenter);
              break;
            default:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Studio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Presets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutePath.settingsCenter),
              icon: const Icon(
                Icons.settings_outlined,
                color: AppColors.textPrimary,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'AIG',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 28,
                    color: AppColors.accentGoldDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutePath.machineCenter),
              icon: const Icon(
                Icons.precision_manufacturing_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.planName});

  final String planName;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Studio Overview',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.accentGoldDark,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Capture Studio',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: compact ? 24 : 30,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              StatusChip(
                label: planName.trim().isEmpty
                    ? 'Subscription unavailable'
                    : planName,
                icon: Icons.workspace_premium_outlined,
                backgroundColor: AppColors.accentGoldLight,
                foregroundColor: AppColors.accentGoldDark,
              ),
              const SizedBox(height: AppSpacing.l),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move from capture to export with confidence.',
                      style: AppTypography.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    SizedBox(
                      width: double.infinity,
                      child: PremiumButton(
                        label: 'Open Studio',
                        icon: const Icon(
                          Icons.play_arrow,
                          color: AppColors.background,
                        ),
                        onPressed: () => GoRouter.of(
                          context,
                        ).push(AppRoutePath.cameraStudio),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Center(
                      child: IconBadge(icon: Icons.star_border, size: 72),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Launch your next capture session in one tap.',
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          PremiumButton(
                            label: 'Open Studio',
                            icon: const Icon(
                              Icons.play_arrow,
                              color: AppColors.background,
                            ),
                            onPressed: () => GoRouter.of(
                              context,
                            ).push(AppRoutePath.cameraStudio),
                            width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.l),
                    const IconBadge(icon: Icons.star_border, size: 84),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MachineStatusCard extends StatelessWidget {
  const _MachineStatusCard({
    required this.machine,
    required this.connectionState,
  });

  final dynamic machine;
  final DeviceConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.secondaryBackground,
                  child: const Center(
                    child: Icon(
                      Icons.desktop_windows,
                      size: 32,
                      color: AppColors.icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DiamondCam',
                      style: AppTypography.headline.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(
                      label: _connectionLabel(connectionState.status),
                      icon: _connectionIcon(connectionState.status),
                      backgroundColor: _connectionColor(connectionState.status),
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    GoRouter.of(context).push(AppRoutePath.machineCenter),
                icon: const Icon(Icons.chevron_right, color: AppColors.icon),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          const PremiumDivider(indent: 0, endIndent: 0),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.sync_alt,
                  value: connectionState.status == ConnectionStatus.connected
                      ? 'Commanded'
                      : 'Idle',
                  label: 'Rotation',
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: MetricTile(
                  icon: Icons.wb_sunny_outlined,
                  value: connectionState.status == ConnectionStatus.connected
                      ? 'GPIO 33'
                      : 'Offline',
                  label: 'Lighting',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.thermostat,
                  value: '—',
                  label: 'Temperature',
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: MetricTile(
                  icon: Icons.shield_outlined,
                  value: _connectionLabel(connectionState.status),
                  label: 'Status',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _connectionLabel(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Protocol Verified';
      case ConnectionStatus.connectedUnverified:
        return 'ESP32 Reachable · Protocol Unverified';
      case ConnectionStatus.transportReachable:
        return 'Transport reachable';
      case ConnectionStatus.verifying:
        return 'Verifying';
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return 'Connecting';
      case ConnectionStatus.failure:
      case ConnectionStatus.error:
      case ConnectionStatus.unreachable:
        return 'Unavailable';
      case ConnectionStatus.idle:
      case ConnectionStatus.scanning:
      case ConnectionStatus.disconnected:
        return 'Not connected';
    }
  }

  IconData _connectionIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.check_circle_outline;
      case ConnectionStatus.connectedUnverified:
        return Icons.warning_amber_rounded;
      case ConnectionStatus.transportReachable:
        return Icons.wifi_tethering;
      case ConnectionStatus.verifying:
        return Icons.hourglass_top_outlined;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Icons.sync;
      case ConnectionStatus.failure:
      case ConnectionStatus.error:
      case ConnectionStatus.unreachable:
        return Icons.error_outline;
      case ConnectionStatus.idle:
      case ConnectionStatus.scanning:
      case ConnectionStatus.disconnected:
        return Icons.link_off;
    }
  }

  Color _connectionColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connectedUnverified:
        return Colors.orange;
      case ConnectionStatus.transportReachable:
        return Colors.orange;
      case ConnectionStatus.verifying:
        return AppColors.accentGoldDark;
      case ConnectionStatus.failure:
      case ConnectionStatus.error:
      case ConnectionStatus.unreachable:
        return Colors.red;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
      case ConnectionStatus.idle:
      case ConnectionStatus.scanning:
      case ConnectionStatus.disconnected:
        return AppColors.textMuted;
    }
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Access'),
        const SizedBox(height: AppSpacing.l),
        LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth;
            if (!available.isFinite || available <= 0) {
              return const SizedBox.shrink();
            }
            final columns = available < 520 ? 2 : 3;
            final gaps = AppSpacing.l * (columns - 1);
            final itemWidth = ((available - gaps) / columns).clamp(
              0.0,
              available,
            );
            return Wrap(
              spacing: AppSpacing.l,
              runSpacing: AppSpacing.l,
              children: [
                _QuickActionCard(
                  label: 'Camera Studio',
                  icon: Icons.camera_alt_outlined,
                  width: itemWidth,
                  onTap: () =>
                      GoRouter.of(context).push(AppRoutePath.cameraStudio),
                ),
                _QuickActionCard(
                  label: 'Presets',
                  icon: Icons.star_border,
                  width: itemWidth,
                  onTap: () =>
                      GoRouter.of(context).push(AppRoutePath.presetStudio),
                ),
                _QuickActionCard(
                  label: 'Gallery',
                  icon: Icons.photo_library_outlined,
                  width: itemWidth,
                  onTap: () => GoRouter.of(context).push(AppRoutePath.gallery),
                ),
                _QuickActionCard(
                  label: 'Export',
                  icon: Icons.upload_outlined,
                  width: itemWidth,
                  onTap: () => GoRouter.of(context).push(AppRoutePath.export),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.width,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.standard,
      width: width,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: AppShadow.soft,
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.accentGoldDark, size: 24),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentCapturesSection extends ConsumerWidget {
  const _RecentCapturesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(galleryListProvider);
    final recentItems = items.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Captures',
          actionLabel: 'View All',
          onAction: () => GoRouter.of(context).push(AppRoutePath.gallery),
        ),
        const SizedBox(height: AppSpacing.l),
        if (recentItems.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: Text(
                'No recent captures yet. Start a session to see them here.',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentItems.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.l),
              itemBuilder: (context, index) {
                final item = recentItems[index];
                return _RecentCaptureCard(
                  title: item.title,
                  mediaType: _mediaTypeLabel(
                    item.mediaType,
                  ).toUpperCase().substring(0, 3),
                  selected: index == 0,
                );
              },
            ),
          ),
      ],
    );
  }
}

String _mediaTypeLabel(dynamic mediaType) {
  switch (mediaType) {
    case MediaType.photo:
      return 'Photo';
    case MediaType.video:
      return 'Video';
    case MediaType.raw:
      return 'RAW';
    case MediaType.edited:
      return 'Edited';
    case MediaType.original:
      return 'Original';
    case MediaType.thumbnail:
      return 'Thumbnail';
    default:
      return 'Media';
  }
}

class _RecentCaptureCard extends StatelessWidget {
  const _RecentCaptureCard({
    required this.title,
    required this.mediaType,
    this.selected = false,
  });

  final String title;
  final String mediaType;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.standard,
      width: 148,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: selected ? AppColors.accentGold : AppColors.border,
        ),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.large),
              ),
              child: Container(
                color: AppColors.secondaryBackground,
                child: const Center(
                  child: Icon(Icons.image, color: AppColors.icon, size: 42),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(mediaType, style: AppTypography.label),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            child: Text(
              title,
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.planName, required this.renewalDate});

  final String planName;
  final DateTime renewalDate;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const IconBadge(icon: Icons.workspace_premium_outlined, size: 62),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$planName Plan',
                      style: AppTypography.headline.copyWith(fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Next billing on ${renewalDate.month}/${renewalDate.day}/${renewalDate.year}',
                      style: AppTypography.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              SizedBox(
                width: compact ? 96 : null,
                child: OutlineButton(
                  label: 'Manage',
                  onPressed: () => GoRouter.of(
                    context,
                  ).push(AppRoutePath.subscriptionCenter),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
