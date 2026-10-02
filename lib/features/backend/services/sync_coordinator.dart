import 'package:aig/features/backend/models/sync_request.dart';
import 'package:aig/features/backend/services/firestore_service.dart';

class SyncCoordinator {
  const SyncCoordinator({required this.firestore});

  final FirestoreService firestore;

  Future<void> sync({required List<SyncRequest> requests}) async {
    for (final request in requests) {
      if (request.operation == SyncOperation.delete) {
        await firestore.deleteDocument(collection: request.collection, documentId: request.documentId);
        continue;
      }

      await firestore.upsertDocument(collection: request.collection, documentId: request.documentId, data: request.payload);
    }
  }
}
