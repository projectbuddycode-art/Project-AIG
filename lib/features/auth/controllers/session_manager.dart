import 'package:aig/features/auth/models/authenticated_user.dart';

class SessionManager {
  const SessionManager();

  bool isSessionExpired(DateTime? lastRefreshedAt) {
    if (lastRefreshedAt == null) {
      return false;
    }
    final age = DateTime.now().difference(lastRefreshedAt);
    return age.inMinutes > 60;
  }

  String buildSessionKey(AuthenticatedUser user) {
    return 'session:${user.uid}';
  }
}
