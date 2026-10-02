import 'package:flutter/foundation.dart';

@immutable
class AuthError {
  const AuthError({
    required this.code,
    required this.message,
    this.isRetryable = false,
  });

  final String code;
  final String message;
  final bool isRetryable;

  factory AuthError.invalidCredentials() {
    return const AuthError(code: 'invalid-credentials', message: 'Invalid email or password.');
  }

  factory AuthError.network() {
    return const AuthError(code: 'network-error', message: 'Network failure. Please try again.');
  }

  factory AuthError.disabledAccount() {
    return const AuthError(code: 'disabled-account', message: 'This account has been disabled.');
  }

  factory AuthError.tooManyAttempts() {
    return const AuthError(code: 'too-many-attempts', message: 'Too many attempts. Please try again later.');
  }

  factory AuthError.unknown({String? message}) {
    return AuthError(code: 'unknown-error', message: message ?? 'Unknown error.');
  }
}
