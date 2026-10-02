
class VideoInspection {
  const VideoInspection({
    required this.valid,
    required this.message,
    this.path,
    this.width = 0,
    this.height = 0,
    this.durationMs = 0,
    this.rotation = 0,
    this.bitrate = 0,
    this.sizeBytes = 0,
    this.frameRate = 0,
    this.mimeType,
  });

  final bool valid;
  final String message;
  final String? path;
  final int width;
  final int height;
  final int durationMs;
  final int rotation;
  final int bitrate;
  final int sizeBytes;
  final double frameRate;
  final String? mimeType;

  int get shortestEdge {
    if (width <= 0 || height <= 0) {
      return 0;
    }
    return width < height ? width : height;
  }

  int get squareOutputEdge {
    final edge = shortestEdge;
    if (edge <= 0) {
      return 0;
    }
    final even = edge - (edge % 2);
    return even > 1080 ? 1080 : even;
  }

  bool get isPlausibleDuration => durationMs >= 400 && durationMs <= 120000;

  factory VideoInspection.fromMap(Map<dynamic, dynamic> map) {
    return VideoInspection(
      valid: map['valid'] == true,
      message: map['message'] as String? ?? '',
      path: map['path'] as String?,
      width: (map['width'] as num?)?.round() ?? 0,
      height: (map['height'] as num?)?.round() ?? 0,
      durationMs: (map['durationMs'] as num?)?.round() ?? 0,
      rotation: (map['rotation'] as num?)?.round() ?? 0,
      bitrate: (map['bitrate'] as num?)?.round() ?? 0,
      sizeBytes: (map['sizeBytes'] as num?)?.round() ?? 0,
      frameRate: (map['frameRate'] as num?)?.toDouble() ?? 0,
      mimeType: map['mimeType'] as String?,
    );
  }
}
