import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:aig/features/auth/models/auth_error.dart';
import 'package:aig/features/auth/models/authenticated_user.dart';
import 'package:aig/features/auth/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  FirebaseAuth? _resolveAuth() {
    if (_auth != null) {
      return _auth;
    }

    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AuthenticatedUser?> signInWithEmailAndPassword({required String email, required String password, bool rememberLogin = true}) async {
    final auth = _resolveAuth();
    if (auth == null) {
      throw AuthException(AuthError.network());
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      return user == null ? null : _mapUser(user);
    } on FirebaseAuthException catch (exception) {
      throw AuthException(_mapFirebaseException(exception));
    } on PlatformException catch (exception) {
      throw AuthException(_mapPlatformException(exception));
    } catch (_) {
      throw AuthException(AuthError.network());
    }
  }

  @override
  Future<void> signOut() async {
    final auth = _resolveAuth();
    if (auth == null) {
      return;
    }

    await auth.signOut();
  }

  @override
  Future<AuthenticatedUser?> restoreSession() async {
    final auth = _resolveAuth();
    final user = auth?.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final auth = _resolveAuth();
    if (auth == null) {
      throw AuthException(AuthError.network());
    }

    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (exception) {
      throw AuthException(_mapFirebaseException(exception));
    } on PlatformException catch (exception) {
      throw AuthException(_mapPlatformException(exception));
    } catch (_) {
      throw AuthException(AuthError.network());
    }
  }

  @override
  Future<void> refreshSession() async {
    try {
      await _resolveAuth()?.currentUser?.reload();
    } catch (_) {
      // Ignore refresh failures; session restoration remains best effort.
    }
  }

  AuthenticatedUser _mapUser(User user) {
    return AuthenticatedUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  AuthError _mapFirebaseException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return AuthError.invalidCredentials();
      case 'user-disabled':
        return AuthError.disabledAccount();
      case 'too-many-requests':
      case 'too-many-attempts':
        return AuthError.tooManyAttempts();
      case 'network-request-failed':
        return AuthError.network();
      default:
        return AuthError.unknown(message: exception.message);
    }
  }

  AuthError _mapPlatformException(PlatformException exception) {
    if (exception.code.contains('network')) {
      return AuthError.network();
    }
    return AuthError.unknown(message: exception.message);
  }
}

class AuthException implements Exception {
  AuthException(this.error);

  final AuthError error;
}
