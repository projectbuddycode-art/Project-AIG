import 'package:aig/features/gallery/models/media_item.dart';

class ThumbnailGenerator {
  Future<String?> generateThumbnail(MediaItem item) async {
    return item.thumbnailPath ?? item.storagePath;
  }
}
