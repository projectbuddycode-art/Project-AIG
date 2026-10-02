import 'package:flutter/foundation.dart';

import 'package:aig/features/gallery/models/media_album.dart';
import 'package:aig/features/gallery/models/media_item.dart';

@immutable
class MediaCollection {
  final MediaAlbum album;
  final List<MediaAlbum> albums;
  final List<MediaItem> items;

  const MediaCollection({
    required this.album,
    required this.albums,
    required this.items,
  });
}
