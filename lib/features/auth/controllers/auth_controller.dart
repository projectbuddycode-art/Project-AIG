import 'package:aig/features/auth/models/auth_error.dart';
import 'package:aig/features/auth/models/authenticated_user.dart';
import 'package:aig/features/auth/repositories/auth_repository.dart';
import 'package:aig/features/auth/repositories/firebase_auth_repository.dart';

class AuthController {
  AuthController({AuthRepository? repository}) : _repository = repository ?? FirebaseAuthRepository();

  final AuthRepository _repository;

  Future<AuthenticatedUser?> signInWithEmailAndPassword({required String email, required String password, bool rememberLogin = true}) async {
    try {
      return await _repository.signInWithEmailAndPassword(email: email, password: password, rememberLogin: rememberLogin);
    } on AuthException catch (exception) {
      throw exception.error;
    } catch (_) {
      throw AuthError.unknown();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  Future<AuthenticatedUser?> restoreSession() async {
    try {
      return await _repository.restoreSession();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _repository.sendPasswordResetEmail(email: email);
    } on AuthException catch (exception) {
      throw exception.error;
    } catch (_) {
      throw AuthError.unknown();
    }
  }

  Future<void> refreshSession() async {
    await _repository.refreshSession();
  }
}
