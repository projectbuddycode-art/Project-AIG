import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_metadata.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'package:aig/features/gallery/models/media_sort.dart';
import 'package:aig/features/gallery/managers/gallery_manager.dart';
import 'package:aig/features/gallery/repositories/in_memory_gallery_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GalleryManager', () {
    test('sorts media by newest date first', () async {
      final repository = InMemoryGalleryRepository();
      final manager = GalleryManager(repository: repository);

      final older = MediaItem(
        id: 'older',
        title: 'Older',
        mediaType: MediaType.photo,
        storagePath: '/tmp/older.jpg',
        createdAt: DateTime(2024, 1, 1),
        metadata: const MediaMetadata(),
      );

      final newer = MediaItem(
        id: 'newer',
        title: 'Newer',
        mediaType: MediaType.photo,
        storagePath: '/tmp/newer.jpg',
        createdAt: DateTime(2025, 1, 1),
        metadata: const MediaMetadata(),
      );

      await manager.addMedia(older);
      await manager.addMedia(newer);

      final result = await manager.listMedia(sort: MediaSort.newest);

      expect(result.items.first.id, 'newer');
      expect(result.items.last.id, 'older');
    });

    test('filters media by type', () async {
      final repository = InMemoryGalleryRepository();
      final manager = GalleryManager(repository: repository);

      await manager.addMedia(
        MediaItem(
          id: 'photo',
          title: 'Photo',
          mediaType: MediaType.photo,
          storagePath: '/tmp/photo.jpg',
          createdAt: DateTime(2025, 1, 1),
          metadata: const MediaMetadata(),
        ),
      );
      await manager.addMedia(
        MediaItem(
          id: 'video',
          title: 'Video',
          mediaType: MediaType.video,
          storagePath: '/tmp/video.mp4',
          createdAt: DateTime(2025, 1, 2),
          metadata: const MediaMetadata(),
        ),
      );

      final result = await manager.listMedia(filter: MediaFilter(type: MediaType.photo));

      expect(result.items.length, 1);
      expect(result.items.first.id, 'photo');
    });
  });
}
