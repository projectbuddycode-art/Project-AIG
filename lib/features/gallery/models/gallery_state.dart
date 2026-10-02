import 'package:flutter/foundation.dart';

import 'package:aig/features/gallery/models/media_album.dart';
import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_sort.dart';

@immutable
class GalleryState {
  final List<MediaItem> items;
  final List<MediaAlbum> albums;
  final MediaAlbum selectedAlbum;
  final MediaFilter filter;
  final MediaSort sort;
  final String searchQuery;

  const GalleryState({
    required this.items,
    required this.albums,
    required this.selectedAlbum,
    required this.filter,
    required this.sort,
    required this.searchQuery,
  });

  factory GalleryState.initial() => const GalleryState(
        items: <MediaItem>[],
        albums: <MediaAlbum>[],
        selectedAlbum: MediaAlbum(id: 'all', name: 'All Media', isSystemAlbum: true),
        filter: MediaFilter(),
        sort: MediaSort.newest,
        searchQuery: '',
      );
}
