class FirestoreService {
  const FirestoreService();

  Future<void> createDocument({required String collection, required String documentId, required Map<String, Object?> data}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> updateDocument({required String collection, required String documentId, required Map<String, Object?> data}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> upsertDocument({required String collection, required String documentId, required Map<String, Object?> data}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> deleteDocument({required String collection, required String documentId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<Map<String, Object?>> readDocument({required String collection, required String documentId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return <String, Object?>{};
  }

  String collectionPath(String collection) {
    return collection;
  }
}
