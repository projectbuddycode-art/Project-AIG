import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/repositories/gallery_repository.dart';
import 'package:path_provider/path_provider.dart';

/// FileGalleryRepository persists media items to local JSON storage.
/// Provides durability across app restarts.
class FileGalleryRepository implements GalleryRepository {
  late final Directory _storageDir;
  late final File _indexFile;
  List<MediaItem>? _cachedItems;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _storageDir = Directory('${dir.path}/gallery');
    _indexFile = File('${_storageDir.path}/index.json');
    
    // Create directory if needed
    if (!_storageDir.existsSync()) {
      await _storageDir.create(recursive: true);
    }
    
    // Load existing index
    if (_indexFile.existsSync()) {
      await _load();
    } else {
      _cachedItems = [];
    }
    
    _initialized = true;
  }

  @override
  Future<void> add(MediaItem item) async {
    await _ensureInitialized();

    if (item.storagePath.startsWith('content://')) {
      if (item.metadata.fileSizeBytes != null && item.metadata.fileSizeBytes! <= 0) {
        throw ArgumentError('MediaStore item is empty: ${item.storagePath}');
      }
    } else {
      final file = File(item.storagePath);
      if (!file.existsSync()) {
        throw ArgumentError('Media file does not exist at: ${item.storagePath}');
      }
      final size = await file.length();
      if (size == 0) {
        throw ArgumentError('Media file is empty (0 bytes): ${item.storagePath}');
      }
    }
    
    // Load current items if not already cached
    _cachedItems ??= [];
    
    // Remove if already exists (update)
    _cachedItems!.removeWhere((i) => i.id == item.id);
    
    // Add new item
    _cachedItems!.add(item);
    
    // Persist to disk
    await _save();
  }

  @override
  Future<void> remove(String id) async {
    await _ensureInitialized();
    _cachedItems ??= [];
    
    _cachedItems!.removeWhere((i) => i.id == id);
    await _save();
  }

  @override
  Future<List<MediaItem>> list() async {
    await _ensureInitialized();
    _cachedItems ??= [];
    return List.from(_cachedItems ?? []);
  }

  @override
  Future<MediaItem?> get(String id) async {
    await _ensureInitialized();
    _cachedItems ??= [];
    
    try {
      return _cachedItems!.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<MediaItem>> _load() async {
    try {
      if (!_indexFile.existsSync()) {
        return [];
      }
      
      final content = await _indexFile.readAsString();
      final json = jsonDecode(content) as List<dynamic>;
      
      _cachedItems = json
          .map((item) {
            try {
              return MediaItem.fromJson(Map<String, dynamic>.from(item as Map));
            } catch (error) {
              developer.log('Skipping corrupt gallery item: $error', name: 'FileGalleryRepository');
              return null;
            }
          })
          .whereType<MediaItem>()
          .toList();
      return _cachedItems!;
    } catch (e) {
      developer.log('Error loading gallery index: $e', name: 'FileGalleryRepository');
      _cachedItems = [];
      return [];
    }
  }

  Future<void> _save() async {
    try {
      final json = jsonEncode((_cachedItems ?? []).map((i) => i.toJson()).toList());
      await _indexFile.writeAsString(json);
    } catch (e) {
      developer.log('Error saving gallery index: $e', name: 'FileGalleryRepository');
      rethrow;
    }
  }
}
