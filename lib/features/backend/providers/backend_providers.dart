import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/backend/services/analytics_service.dart';
import 'package:aig/features/backend/services/backend_manager.dart';
import 'package:aig/features/backend/services/crash_reporting_service.dart';
import 'package:aig/features/backend/services/firestore_service.dart';
import 'package:aig/features/backend/services/notification_service.dart';
import 'package:aig/features/backend/services/remote_config_service.dart';
import 'package:aig/features/backend/services/storage_service.dart';
import 'package:aig/features/backend/services/sync_coordinator.dart';
import 'package:aig/features/backend/services/user_profile_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return const FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return const StorageService();
});

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return const RemoteConfigService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return const NotificationService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const AnalyticsService();
});

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return const CrashReportingService();
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(firestore: ref.read(firestoreServiceProvider));
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  return SyncCoordinator(firestore: ref.read(firestoreServiceProvider));
});

final backendManagerProvider = Provider<BackendManager>((ref) {
  return BackendManager(
    firestore: ref.read(firestoreServiceProvider),
    storage: ref.read(storageServiceProvider),
    remoteConfig: ref.read(remoteConfigServiceProvider),
    notifications: ref.read(notificationServiceProvider),
    analytics: ref.read(analyticsServiceProvider),
    crashReporting: ref.read(crashReportingServiceProvider),
    userProfile: ref.read(userProfileServiceProvider),
    syncCoordinator: ref.read(syncCoordinatorProvider),
  );
});
