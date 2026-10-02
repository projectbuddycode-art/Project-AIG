import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/rotation_config.dart';
import 'package:aig/features/esp32/models/lighting_config.dart';

@immutable
class PresetModel {
  final String id;
  final String name;
  final RotationConfig rotation;
  final LightingConfig lighting;
  final Duration captureDelay;
  final String cameraTriggerMode;
  final Map<String, dynamic>? extraFlags;

  const PresetModel({
    required this.id,
    required this.name,
    required this.rotation,
    required this.lighting,
    this.captureDelay = const Duration(seconds: 0),
    this.cameraTriggerMode = 'immediate',
    this.extraFlags,
  });
}
