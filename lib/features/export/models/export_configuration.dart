import 'package:flutter/foundation.dart';

@immutable
class ExportConfiguration {
  const ExportConfiguration({
    this.format = ExportFormat.jpeg,
    this.quality = 0.9,
    this.resolution = ExportResolution.original,
    this.compression = 0.0,
    this.filename = 'export',
    this.destination = ExportDestination.localStorage,
    this.metadata = const <String, Object?>{},
  });

  final ExportFormat format;
  final double quality;
  final ExportResolution resolution;
  final double compression;
  final String filename;
  final ExportDestination destination;
  final Map<String, Object?> metadata;

  ExportConfiguration copyWith({
    ExportFormat? format,
    double? quality,
    ExportResolution? resolution,
    double? compression,
    String? filename,
    ExportDestination? destination,
    Map<String, Object?>? metadata,
  }) {
    return ExportConfiguration(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      resolution: resolution ?? this.resolution,
      compression: compression ?? this.compression,
      filename: filename ?? this.filename,
      destination: destination ?? this.destination,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum ExportFormat {
  jpeg,
  png,
  raw,
  heif,
  tiff,
  mp4,
  mov,
}

enum ExportResolution {
  original,
  hd,
  fullHd,
  ultraHd,
}

enum ExportDestination {
  localStorage,
  gallery,
  shareSheet,
  externalStorage,
}
