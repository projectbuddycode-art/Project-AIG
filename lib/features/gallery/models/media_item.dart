import 'package:flutter/foundation.dart';

import 'package:aig/features/gallery/models/media_metadata.dart';
import 'package:aig/features/gallery/models/media_type.dart';

@immutable
class MediaItem {
  final String id;
  final String title;
  final MediaType mediaType;
  final String storagePath;
  final DateTime createdAt;
  final bool isFavorite;
  final String? thumbnailPath;
  final MediaMetadata metadata;

  const MediaItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.storagePath,
    required this.createdAt,
    this.isFavorite = false,
    this.thumbnailPath,
    this.metadata = const MediaMetadata(),
  });

  MediaItem copyWith({
    String? id,
    String? title,
    MediaType? mediaType,
    String? storagePath,
    DateTime? createdAt,
    bool? isFavorite,
    String? thumbnailPath,
    MediaMetadata? metadata,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'mediaType': mediaType.name,
      'storagePath': storagePath,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'thumbnailPath': thumbnailPath,
      'metadata': metadata.toJson(),
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      mediaType: MediaType.values.firstWhere(
        (type) => type.name == json['mediaType'],
        orElse: () => MediaType.photo,
      ),
      storagePath: json['storagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      thumbnailPath: json['thumbnailPath'] as String?,
      metadata: MediaMetadata.fromJson(
        json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}
