import 'package:aig/features/gallery/managers/gallery_manager.dart';
import 'package:aig/features/gallery/models/gallery_state.dart';
import 'package:aig/features/gallery/models/media_album.dart';
import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_sort.dart';

class GalleryController {
  GalleryController({required GalleryManager manager}) : _manager = manager;

  final GalleryManager _manager;

  Future<void> addMedia(MediaItem item) => _manager.addMedia(item);

  Future<void> removeMedia(String id) => _manager.removeMedia(id);

  Future<GalleryState> loadState({MediaAlbum? album, MediaFilter? filter, MediaSort? sort, String searchQuery = ''}) async {
    final result = await _manager.listMedia(album: album, filter: filter, sort: sort, searchQuery: searchQuery);
    return GalleryState(
      items: result.items,
      albums: result.albums,
      selectedAlbum: album ??
          (result.albums.isNotEmpty
              ? result.albums.first
              : const MediaAlbum(id: 'all', name: 'All Media', isSystemAlbum: true)),
      filter: filter ?? const MediaFilter(),
      sort: sort ?? MediaSort.newest,
      searchQuery: searchQuery,
    );
  }
}
