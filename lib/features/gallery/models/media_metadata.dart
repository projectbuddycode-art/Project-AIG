import 'package:flutter/foundation.dart';

@immutable
class MediaMetadata {
  final DateTime? captureDate;
  final String? device;
  final String? cameraSettings;
  final String? rotationSettings;
  final String? lightingSettings;
  final String? captureSessionId;
  final String? presetUsed;
  final int? imageWidth;
  final int? imageHeight;
  final int? resolutionWidth;
  final int? resolutionHeight;
  final Duration? duration;
  final int? fileSizeBytes;
  final List<String> aiTags;
  final int? rating;
  final String? notes;

  const MediaMetadata({
    this.captureDate,
    this.device,
    this.cameraSettings,
    this.rotationSettings,
    this.lightingSettings,
    this.captureSessionId,
    this.presetUsed,
    this.imageWidth,
    this.imageHeight,
    this.resolutionWidth,
    this.resolutionHeight,
    this.duration,
    this.fileSizeBytes,
    this.aiTags = const <String>[],
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'captureDate': captureDate?.toIso8601String(),
      'device': device,
      'cameraSettings': cameraSettings,
      'rotationSettings': rotationSettings,
      'lightingSettings': lightingSettings,
      'captureSessionId': captureSessionId,
      'presetUsed': presetUsed,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'resolutionWidth': resolutionWidth,
      'resolutionHeight': resolutionHeight,
      'durationSeconds': duration?.inSeconds,
      'fileSizeBytes': fileSizeBytes,
      'aiTags': aiTags,
      'rating': rating,
      'notes': notes,
    };
  }

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      captureDate: json['captureDate'] != null
          ? DateTime.parse(json['captureDate'] as String)
          : null,
      device: json['device'] as String?,
      cameraSettings: json['cameraSettings'] as String?,
      rotationSettings: json['rotationSettings'] as String?,
      lightingSettings: json['lightingSettings'] as String?,
      captureSessionId: json['captureSessionId'] as String?,
      presetUsed: json['presetUsed'] as String?,
      imageWidth: json['imageWidth'] as int?,
      imageHeight: json['imageHeight'] as int?,
      resolutionWidth: json['resolutionWidth'] as int?,
      resolutionHeight: json['resolutionHeight'] as int?,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: (json['durationSeconds'] as num).round())
          : null,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      aiTags: (json['aiTags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
    );
  }
}
