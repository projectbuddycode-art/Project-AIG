import 'package:flutter/foundation.dart';

@immutable
class MediaAlbum {
  final String id;
  final String name;
  final String description;
  final bool isSystemAlbum;

  const MediaAlbum({
    required this.id,
    required this.name,
    this.description = '',
    this.isSystemAlbum = false,
  });
}
