import 'package:flutter/foundation.dart';

import 'package:aig/core/config/app_config.dart';
import 'package:aig/features/auth/controllers/auth_controller.dart';
import 'package:aig/features/auth/models/auth_error.dart';
import 'package:aig/features/auth/models/auth_state.dart';
import 'package:aig/features/auth/models/authenticated_user.dart';

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier({AuthController? controller})
      : _controller = controller ?? AuthController(),
        _state = const AuthState();

  final AuthController _controller;
  AuthState _state;

  AuthState get state => _state;

  Future<void> restoreSession() async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    if (AppConfig.enableLocalTestingMode) {
      final testUser = AuthenticatedUser(
        uid: 'local-test-user',
        email: 'local-test@example.com',
        displayName: 'Local Test User',
      );
      _state = _state.copyWith(
        user: testUser,
        isAuthenticated: true,
        isLoading: false,
        isSessionRestored: true,
        error: null,
      );
      notifyListeners();
      return;
    }

    final user = await _controller.restoreSession();
    _state = _state.copyWith(
      user: user,
      isAuthenticated: user != null,
      isLoading: false,
      isSessionRestored: true,
      error: null,
    );
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password, bool rememberLogin = true}) async {
    if (AppConfig.enableLocalTestingMode) {
      final testUser = AuthenticatedUser(
        uid: 'local-test-user',
        email: email,
        displayName: 'Local Test User',
      );
      _state = _state.copyWith(user: testUser, isAuthenticated: true, isLoading: false, error: null, isSessionRestored: true);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final user = await _controller.signInWithEmailAndPassword(email: email, password: password, rememberLogin: rememberLogin);
      _state = _state.copyWith(user: user, isAuthenticated: user != null, isLoading: false, error: null);
    } on AuthError catch (error) {
      _state = _state.copyWith(isAuthenticated: false, isLoading: false, error: error);
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    if (AppConfig.enableLocalTestingMode) {
      _state = const AuthState();
      notifyListeners();
      return;
    }

    await _controller.signOut();
    _state = const AuthState();
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _controller.sendPasswordResetEmail(email: email);
      _state = _state.copyWith(isLoading: false, error: null);
    } on AuthError catch (error) {
      _state = _state.copyWith(isLoading: false, error: error);
    }

    notifyListeners();
  }
}
