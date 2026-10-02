import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_sort.dart';

class MediaIndexer {
  List<MediaItem> applyFilter(List<MediaItem> items, MediaFilter filter) {
    var filtered = items;

    if (filter.type != null) {
      filtered = filtered.where((item) => item.mediaType == filter.type).toList();
    }
    if (filter.favoriteOnly == true) {
      filtered = filtered.where((item) => item.isFavorite).toList();
    }
    if (filter.sessionId != null && filter.sessionId!.isNotEmpty) {
      filtered = filtered.where((item) => item.metadata.captureSessionId == filter.sessionId).toList();
    }
    if (filter.preset != null && filter.preset!.isNotEmpty) {
      filtered = filtered.where((item) => item.metadata.presetUsed == filter.preset).toList();
    }
    if (filter.query != null && filter.query!.isNotEmpty) {
      final query = filter.query!.toLowerCase();
      filtered = filtered.where((item) => item.title.toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  List<MediaItem> applySort(List<MediaItem> items, MediaSort sort) {
    final sorted = List<MediaItem>.from(items);

    switch (sort) {
      case MediaSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case MediaSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case MediaSort.name:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case MediaSort.size:
        sorted.sort((a, b) => (b.metadata.fileSizeBytes ?? 0).compareTo(a.metadata.fileSizeBytes ?? 0));
      case MediaSort.session:
        sorted.sort((a, b) => (a.metadata.captureSessionId ?? '').compareTo(b.metadata.captureSessionId ?? ''));
    }

    return sorted;
  }
}
