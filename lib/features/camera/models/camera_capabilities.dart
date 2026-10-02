import 'package:flutter/foundation.dart';

@immutable
class CameraCapabilities {
  final bool supportsRaw;
  final bool supportsHdr;
  final bool supportsHighFps;
  final double maxZoom;
  final double minZoom;
  final bool hasFlash;

  const CameraCapabilities({
    this.supportsRaw = false,
    this.supportsHdr = false,
    this.supportsHighFps = false,
    this.maxZoom = 4.0,
    this.minZoom = 1.0,
    this.hasFlash = false,
  });
}
