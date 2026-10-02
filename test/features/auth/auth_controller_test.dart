import 'package:aig/features/auth/controllers/auth_controller.dart';
import 'package:aig/features/auth/models/auth_error.dart';
import 'package:aig/features/auth/repositories/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthController', () {
    test('returns a structured auth error for invalid credentials', () async {
      final controller = AuthController(repository: FirebaseAuthRepository());
      expect(
        () => controller.signInWithEmailAndPassword(email: 'invalid@example.com', password: 'password'),
        throwsA(isA<AuthError>()),
      );
    });

    test('restoreSession returns null when no active user exists', () async {
      final controller = AuthController(repository: FirebaseAuthRepository());
      final user = await controller.restoreSession();
      expect(user, isNull);
    });
  });
}
