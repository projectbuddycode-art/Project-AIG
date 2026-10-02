import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/gallery/controllers/gallery_controller.dart';
import 'package:aig/features/gallery/managers/gallery_manager.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/repositories/gallery_repository.dart';
import 'package:aig/features/gallery/repositories/file_gallery_repository.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return FileGalleryRepository();
});

final galleryManagerProvider = Provider<GalleryManager>((ref) {
  return GalleryManager(repository: ref.read(galleryRepositoryProvider));
});

final galleryControllerProvider = Provider<GalleryController>((ref) {
  return GalleryController(manager: ref.read(galleryManagerProvider));
});

class GalleryListNotifier extends StateNotifier<List<MediaItem>> {
  GalleryListNotifier(this._controller) : super(const <MediaItem>[]) {
    refresh();
  }

  final GalleryController _controller;

  Future<void> refresh() async {
    try {
      final next = await _controller.loadState();
      if (!mounted) return;
      state = List<MediaItem>.from(next.items);
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> addMedia(MediaItem item) async {
    await _controller.addMedia(item);
    if (!mounted) return;
    state = <MediaItem>[
      item,
      ...state.where((existing) => existing.id != item.id),
    ];
  }
}

final galleryListProvider = StateNotifierProvider<GalleryListNotifier, List<MediaItem>>((ref) {
  ref.keepAlive();
  return GalleryListNotifier(ref.read(galleryControllerProvider));
});
