import 'package:aig/core/router/app_router.dart';
import 'package:aig/core/services/app_lifecycle_service.dart';
import 'package:aig/core/services/firebase_initializer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.create(ref);
});

final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  return AppLifecycleService();
});

final firebaseInitializerProvider = Provider<FirebaseInitializer>((ref) {
  return FirebaseInitializer();
});
