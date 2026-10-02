import 'package:flutter/foundation.dart';

@immutable
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
}
