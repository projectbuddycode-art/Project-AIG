import 'dart:typed_data';

/// Lightweight representation of a preview frame.
class CameraFrame {
  final DateTime timestamp;
  final Uint8List? bytes; // optional raw bytes
  final int width;
  final int height;

  const CameraFrame({
    required this.timestamp,
    this.bytes,
    this.width = 0,
    this.height = 0,
  });
}
