import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/auth/controllers/auth_controller.dart';
import 'package:aig/features/auth/controllers/auth_state_notifier.dart';
import 'package:aig/features/auth/controllers/session_manager.dart';
import 'package:aig/features/auth/repositories/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(repository: ref.read(authRepositoryProvider));
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  return const SessionManager();
});

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(controller: ref.read(authControllerProvider));
});
