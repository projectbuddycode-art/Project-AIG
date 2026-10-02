import 'dart:io';

import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_metadata.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'package:aig/features/gallery/repositories/in_memory_gallery_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gallery_repo_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('persists media across repository instances', () async {
    final repoA = InMemoryGalleryRepository(storageDirectory: tempDir.path);
    final item = MediaItem(
      id: 'capture-1',
      title: 'Studio Capture',
      mediaType: MediaType.photo,
      storagePath: '/tmp/capture-1.jpg',
      createdAt: DateTime(2024, 10, 1, 12, 30),
      metadata: const MediaMetadata(captureSessionId: 'session-1'),
    );

    await repoA.add(item);

    final repoB = InMemoryGalleryRepository(storageDirectory: tempDir.path);
    final saved = await repoB.list();

    expect(saved, hasLength(1));
    expect(saved.single.id, item.id);
    expect(saved.single.title, item.title);
    expect(saved.single.metadata.captureSessionId, 'session-1');
  });
}
