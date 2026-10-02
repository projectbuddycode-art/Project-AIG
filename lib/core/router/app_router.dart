import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/config/app_config.dart';
import 'package:aig/features/auth/presentation/forgot_password_screen.dart';
import 'package:aig/features/auth/presentation/login_screen.dart';
import 'package:aig/features/auth/presentation/splash_screen.dart';
import 'package:aig/features/auth/controllers/auth_guard.dart';
import 'package:aig/features/auth/providers/auth_providers.dart';
import 'package:aig/features/dashboard/presentation/dashboard_screen.dart';
import 'package:aig/features/esp32/presentation/device_connection_screen.dart';
import 'package:aig/features/esp32/presentation/machine_center_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:aig/features/export/presentation/dev_export_monitor_screen.dart';
import 'package:aig/features/export/presentation/premium_export_screen.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/camera/presentation/studio/camera_studio_screen.dart';
import 'package:aig/features/gallery/presentation/gallery_screen.dart';
import 'package:aig/features/preset/presentation/preset_studio_screen.dart';
import 'package:aig/features/settings/presentation/settings_center_screen.dart';
import 'package:aig/features/subscription/presentation/dev_subscription_screen.dart';
import 'package:aig/features/subscription/presentation/subscription_center_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(Ref ref) {
    return GoRouter(
      initialLocation: AppRoutePath.splash,
      redirect: (context, state) {
        if (AppConfig.enableLocalTestingMode) {
          return null;
        }

        final authState = ref.read(authStateNotifierProvider).state;
        final location = state.matchedLocation;

        if (location == AppRoutePath.splash) {
          return null;
        }

        if (!authState.isSessionRestored) {
          return AppRoutePath.splash;
        }

        if (location == AppRoutePath.forgotPassword) {
          return null;
        }

        if (location == AppRoutePath.login) {
          return authState.isAuthenticated ? AppRoutePath.dashboard : null;
        }

        if (!authState.isAuthenticated) {
          return AppRoutePath.login;
        }

        return null;
      },
      routes: <GoRoute>[
        GoRoute(
          path: AppRoutePath.splash,
          name: AppRoutePath.splashName,
          builder: (context, state) => const AuthSplashScreen(),
        ),
        GoRoute(
          path: AppRoutePath.login,
          name: AppRoutePath.loginName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.dashboard,
            redirectIfAuthenticated: true,
            child: AuthLoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.forgotPassword,
          name: AppRoutePath.forgotPasswordName,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutePath.dashboard,
          name: AppRoutePath.dashboardName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.deviceConnection,
          name: AppRoutePath.deviceConnectionName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: DeviceConnectionScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.machineCenter,
          name: AppRoutePath.machineCenterName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: MachineCenterScreen(),
          ),
        ),
        if (kDebugMode) ...[
          GoRoute(
            path: AppRoutePath.exportMonitor,
            name: AppRoutePath.exportMonitorName,
            builder: (context, state) => const DevExportMonitorScreen(),
          ),
          GoRoute(
            path: AppRoutePath.subscriptionMonitor,
            name: AppRoutePath.subscriptionMonitorName,
            builder: (context, state) => const DevSubscriptionScreen(),
          ),
        ],
        GoRoute(
          path: AppRoutePath.subscriptionCenter,
          name: AppRoutePath.subscriptionCenterName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: SubscriptionCenterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.settingsCenter,
          name: AppRoutePath.settingsCenterName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: SettingsCenterScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.export,
          name: AppRoutePath.exportName,
          builder: (context, state) {
            final extra = state.extra;
            List<MediaItem>? selection;
            if (extra is List && extra.isNotEmpty && extra.first is MediaItem) {
              selection = List<MediaItem>.from(extra.cast<MediaItem>());
            }
            return AuthGuard(
              redirectTo: AppRoutePath.login,
              child: PremiumExportScreen(initialSelection: selection),
            );
          },
        ),
        GoRoute(
          path: AppRoutePath.cameraStudio,
          name: AppRoutePath.cameraStudioName,
          builder: (context, state) {
            final extra = state.extra;
            final presetId = extra is String ? extra : null;
            return AuthGuard(
              redirectTo: AppRoutePath.login,
              child: CameraStudioScreen(initialPresetId: presetId),
            );
          },
        ),
        GoRoute(
          path: AppRoutePath.presetStudio,
          name: AppRoutePath.presetStudioName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: PresetStudioScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutePath.gallery,
          name: AppRoutePath.galleryName,
          builder: (context, state) => const AuthGuard(
            redirectTo: AppRoutePath.login,
            child: GalleryScreen(),
          ),
        ),
      ],
    );
  }
}
