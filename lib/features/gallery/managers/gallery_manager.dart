import 'package:aig/features/gallery/models/media_album.dart';
import 'package:aig/features/gallery/models/media_collection.dart';
import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_sort.dart';
import 'package:aig/features/gallery/repositories/gallery_repository.dart';
import 'package:aig/features/gallery/services/media_indexer.dart';
import 'package:aig/features/gallery/services/thumbnail_generator.dart';

class GalleryManager {
  GalleryManager({required GalleryRepository repository})
      : _repository = repository,
        _indexer = MediaIndexer(),
        _thumbnailGenerator = ThumbnailGenerator();

  final GalleryRepository _repository;
  final MediaIndexer _indexer;
  final ThumbnailGenerator _thumbnailGenerator;

  Future<void> addMedia(MediaItem item) async {
    final thumbnail = await _thumbnailGenerator.generateThumbnail(item);
    await _repository.add(item.copyWith(thumbnailPath: thumbnail));
  }

  Future<void> removeMedia(String id) async {
    await _repository.remove(id);
  }

  Future<MediaCollection> listMedia({
    MediaAlbum? album,
    MediaFilter? filter,
    MediaSort? sort,
    String searchQuery = '',
  }) async {
    final items = await _repository.list();
    var filtered = _indexer.applyFilter(items, filter ?? const MediaFilter(query: ''));
    if (searchQuery.isNotEmpty) {
      filtered = _indexer.applyFilter(filtered, MediaFilter(query: searchQuery));
    }
    final sorted = _indexer.applySort(filtered, sort ?? MediaSort.newest);

    final albums = <MediaAlbum>[
      const MediaAlbum(id: 'all', name: 'All Media', isSystemAlbum: true),
      const MediaAlbum(id: 'photos', name: 'Photos', isSystemAlbum: true),
      const MediaAlbum(id: 'videos', name: 'Videos', isSystemAlbum: true),
      const MediaAlbum(id: 'favorites', name: 'Favorites', isSystemAlbum: true),
      const MediaAlbum(id: 'recent', name: 'Recent', isSystemAlbum: true),
      const MediaAlbum(id: 'sessions', name: 'Capture Sessions', isSystemAlbum: true),
    ];

    return MediaCollection(
      album: album ?? albums.first,
      albums: albums,
      items: sorted,
    );
  }
}
