import 'package:aig/features/backend/services/analytics_service.dart';
import 'package:aig/features/backend/services/crash_reporting_service.dart';
import 'package:aig/features/backend/services/firestore_service.dart';
import 'package:aig/features/backend/services/notification_service.dart';
import 'package:aig/features/backend/services/remote_config_service.dart';
import 'package:aig/features/backend/services/storage_service.dart';
import 'package:aig/features/backend/services/sync_coordinator.dart';
import 'package:aig/features/backend/services/user_profile_service.dart';

class BackendManager {
  const BackendManager({
    required this.firestore,
    required this.storage,
    required this.remoteConfig,
    required this.notifications,
    required this.analytics,
    required this.crashReporting,
    required this.userProfile,
    required this.syncCoordinator,
  });

  final FirestoreService firestore;
  final StorageService storage;
  final RemoteConfigService remoteConfig;
  final NotificationService notifications;
  final AnalyticsService analytics;
  final CrashReportingService crashReporting;
  final UserProfileService userProfile;
  final SyncCoordinator syncCoordinator;
}
