import 'package:aig/features/auth/models/auth_error.dart';
import 'package:aig/features/auth/models/authenticated_user.dart';

abstract class AuthRepository {
  Future<AuthenticatedUser?> signInWithEmailAndPassword({required String email, required String password, bool rememberLogin = true});
  Future<void> signOut();
  Future<AuthenticatedUser?> restoreSession();
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> refreshSession();
}

class AuthResult {
  const AuthResult({required this.user, required this.error});

  final AuthenticatedUser? user;
  final AuthError? error;
}
