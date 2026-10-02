import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/repositories/gallery_repository.dart';

class InMemoryGalleryRepository implements GalleryRepository {
  InMemoryGalleryRepository({String? storageDirectory})
      : _storageDirectory = storageDirectory;

  final String? _storageDirectory;
  final List<MediaItem> _items = <MediaItem>[];
  bool _initialized = false;
  Future<void>? _initializationFuture;
  late final String _directoryPath;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    if (_initializationFuture != null) {
      await _initializationFuture;
      return;
    }

    _initializationFuture = _initializeOnce();
    try {
      await _initializationFuture;
    } finally {
      if (!_initialized) {
        _initializationFuture = null;
      }
    }
  }

  Future<void> _initializeOnce() async {
    final resolvedDirectory = _storageDirectory ?? await _defaultStorageDirectory();

    final directory = Directory(resolvedDirectory);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    _directoryPath = directory.path;
    final storageFile = File(_storagePath);
    if (storageFile.existsSync()) {
      final contents = storageFile.readAsStringSync();
      if (contents.isNotEmpty) {
        final decoded = jsonDecode(contents) as List<dynamic>;
        _items.addAll(
          decoded
              .map((item) => MediaItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
        );
      }
    }

    _initialized = true;
  }

  String get _storagePath => '$_directoryPath/gallery_media.json';

  Future<String> _defaultStorageDirectory() async {
    try {
      return '${(await getApplicationDocumentsDirectory()).path}/gallery';
    } catch (_) {
      // Pure Dart tests do not provide a path-provider platform binding.
      return Directory.systemTemp.createTempSync('aig_gallery_test_').path;
    }
  }

  Future<void> _persist() async {
    final storageFile = File(_storagePath);
    final payload = jsonEncode(_items.map((item) => item.toJson()).toList());
    storageFile.writeAsStringSync(payload);
  }

  @override
  Future<void> add(MediaItem item) async {
    await _ensureInitialized();
    _items.removeWhere((existing) => existing.id == item.id);
    _items.add(item);
    await _persist();
  }

  @override
  Future<void> remove(String id) async {
    await _ensureInitialized();
    _items.removeWhere((item) => item.id == id);
    await _persist();
  }

  @override
  Future<List<MediaItem>> list() async {
    await _ensureInitialized();
    return List<MediaItem>.unmodifiable(_items);
  }

  @override
  Future<MediaItem?> get(String id) async {
    await _ensureInitialized();
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
