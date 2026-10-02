import 'package:flutter/foundation.dart';

@immutable
class SyncRequest {
  const SyncRequest({
    required this.collection,
    required this.documentId,
    required this.payload,
    this.operation = SyncOperation.upsert,
    this.retryCount = 0,
  });

  final String collection;
  final String documentId;
  final Map<String, Object?> payload;
  final SyncOperation operation;
  final int retryCount;
}

enum SyncOperation {
  upsert,
  delete,
}
