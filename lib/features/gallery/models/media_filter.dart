import 'package:aig/features/gallery/models/media_type.dart';

class MediaFilter {
  final MediaType? type;
  final bool? favoriteOnly;
  final String? sessionId;
  final String? preset;
  final String? query;

  const MediaFilter({
    this.type,
    this.favoriteOnly,
    this.sessionId,
    this.preset,
    this.query,
  });
}
