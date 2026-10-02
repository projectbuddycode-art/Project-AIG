import 'package:flutter/foundation.dart';

import 'package:aig/features/auth/models/authenticated_user.dart';
import 'package:aig/features/auth/models/auth_error.dart';

@immutable
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.isSessionRestored = false,
  });

  final AuthenticatedUser? user;
  final bool isLoading;
  final bool isAuthenticated;
  final AuthError? error;
  final bool isSessionRestored;

  AuthState copyWith({
    AuthenticatedUser? user,
    bool? isLoading,
    bool? isAuthenticated,
    AuthError? error,
    bool? isSessionRestored,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
      isSessionRestored: isSessionRestored ?? this.isSessionRestored,
    );
  }
}
