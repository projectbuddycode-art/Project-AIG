import 'package:aig/features/gallery/models/media_item.dart';

abstract class GalleryRepository {
  Future<void> add(MediaItem item);
  Future<void> remove(String id);
  Future<List<MediaItem>> list();
  Future<MediaItem?> get(String id);
}
