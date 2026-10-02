import 'package:aig/features/backend/models/backend_collection.dart';
import 'package:aig/features/backend/services/firestore_service.dart';

class UserProfileService {
  const UserProfileService({required this.firestore});

  final FirestoreService firestore;

  Future<void> saveProfile({required String userId, required Map<String, Object?> profile}) async {
    await firestore.updateDocument(collection: BackendCollection.users, documentId: userId, data: profile);
  }

  Future<Map<String, Object?>> loadProfile({required String userId}) async {
    return firestore.readDocument(collection: BackendCollection.users, documentId: userId);
  }
}
