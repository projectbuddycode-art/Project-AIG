import 'dart:typed_data';

class CaptureResult {
  final DateTime timestamp;
  final Uint8List? jpeg;
  final Uint8List? raw;
  final String? videoPath;
  final int width;
  final int height;

  const CaptureResult({
    required this.timestamp,
    this.jpeg,
    this.raw,
    this.videoPath,
    this.width = 0,
    this.height = 0,
  });
}
