enum MediaSort {
  newest,
  oldest,
  name,
  size,
  session,
}

extension MediaSortX on MediaSort {
  String get label {
    switch (this) {
      case MediaSort.newest:
        return 'Newest';
      case MediaSort.oldest:
        return 'Oldest';
      case MediaSort.name:
        return 'Name';
      case MediaSort.size:
        return 'Size';
      case MediaSort.session:
        return 'Session';
    }
  }
}
