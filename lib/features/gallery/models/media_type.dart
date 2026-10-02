enum MediaType {
  photo,
  video,
  raw,
  edited,
  original,
  thumbnail,
}

extension MediaTypeX on MediaType {
  String get label {
    switch (this) {
      case MediaType.photo:
        return 'Photo';
      case MediaType.video:
        return 'Video';
      case MediaType.raw:
        return 'RAW';
      case MediaType.edited:
        return 'Edited';
      case MediaType.original:
        return 'Original';
      case MediaType.thumbnail:
        return 'Thumbnail';
    }
  }
}
