import 'package:flutter/foundation.dart';

@immutable
class CaptureSettings {
  final int jpegQuality; // 0-100
  final bool enableRaw;
  final int targetWidth;
  final int targetHeight;

  const CaptureSettings({
    this.jpegQuality = 90,
    this.enableRaw = false,
    this.targetWidth = 0,
    this.targetHeight = 0,
  });

  CaptureSettings copyWith({
    int? jpegQuality,
    bool? enableRaw,
    int? targetWidth,
    int? targetHeight,
  }) {
    return CaptureSettings(
      jpegQuality: jpegQuality ?? this.jpegQuality,
      enableRaw: enableRaw ?? this.enableRaw,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
    );
  }
}
