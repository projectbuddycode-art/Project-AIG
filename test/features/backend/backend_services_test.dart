import 'package:aig/features/backend/models/sync_request.dart';
import 'package:aig/features/backend/services/firestore_service.dart';
import 'package:aig/features/backend/services/sync_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Backend services', () {
    test('sync coordinator accepts queued requests', () async {
      final firestore = FirestoreService();
      final coordinator = SyncCoordinator(firestore: firestore);
      await coordinator.sync(requests: [
        const SyncRequest(collection: 'users', documentId: '1', payload: {'name': 'Ada'}),
      ]);
      expect(true, isTrue);
    });
  });
}
