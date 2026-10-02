import 'dart:io';

import 'package:flutter/services.dart';

import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/processing/models/video_inspection.dart';
import 'package:aig/features/processing/services/jewelry_video_validator.dart';

class JewelryProcessResult {
  const JewelryProcessResult({
    required this.success,
    required this.message,
    this.outputPath,
    this.usedOriginal = false,
    this.elapsedMs = 0,
    this.width = 0,
    this.height = 0,
  });

  final bool success;
  final String message;
  final String? outputPath;
  final bool usedOriginal;
  final int elapsedMs;
  final int width;
  final int height;
}

class JewelryVideoProcessor {
  JewelryVideoProcessor({
    JewelryVideoValidator validator = const JewelryVideoValidator(),
    MethodChannel? channel,
  }) : _validator = validator,
       _channel = channel ?? const MethodChannel('aig.camera/methods');

  final JewelryVideoValidator _validator;
  final MethodChannel _channel;

  Future<VideoInspection> inspect(String sourcePath) async {
    final header = await _validator.validateFile(sourcePath);
    if (!header.valid) {
      return VideoInspection(
        valid: false,
        message: header.message,
        sizeBytes: header.sizeBytes,
      );
    }
    if (!Platform.isAndroid) {
      return VideoInspection(
        valid: true,
        message: 'Header valid. Native stream inspect runs on Android.',
        path: sourcePath,
        sizeBytes: header.sizeBytes,
      );
    }
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'inspectJewelryVideo',
        <String, dynamic>{'sourcePath': sourcePath},
      );
      if (result == null) {
        return VideoInspection(
          valid: false,
          message: 'Inspect returned no data',
          path: sourcePath,
        );
      }
      return VideoInspection.fromMap(result);
    } on PlatformException catch (error) {
      return VideoInspection(
        valid: false,
        message: error.message ?? 'Inspect failed',
        path: sourcePath,
      );
    }
  }

  Future<JewelryProcessResult> process({
    required String sourcePath,
    required CameraPreset preset,
    String? outputPath,
  }) async {
    final started = DateTime.now();
    final validation = await _validator.validateFile(sourcePath);
    if (!validation.valid) {
      return JewelryProcessResult(
        success: false,
        message: validation.message,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    }

    final dest =
        outputPath ??
        sourcePath.replaceFirst(
          RegExp(r'\.mp4$', caseSensitive: false),
          '_processed.mp4',
        );
    if (dest == sourcePath) {
      return JewelryProcessResult(
        success: false,
        message:
            'Processed output path must be different from the original recording',
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    }

    if (!Platform.isAndroid) {
      return JewelryProcessResult(
        success: true,
        message:
            'Native jewelry grading runs on Android. Original recording kept (${preset.processingLook.name}).',
        outputPath: sourcePath,
        usedOriginal: true,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'processJewelryVideo',
        <String, dynamic>{
          'sourcePath': sourcePath,
          'outputPath': dest,
          'look': preset.processingLook.name,
          'aspectRatio': preset.aspectRatio,
          'background': preset.backgroundTreatment.name,
          'allowUpscale': preset.allowUpscale,
          'strength': preset.filterStrength,
        },
      );
      final ok = result?['success'] == true;
      final path = result?['outputPath'] as String?;
      final message = result?['message'] as String? ?? 'Processing finished';
      final width = (result?['width'] as num?)?.round() ?? 0;
      final height = (result?['height'] as num?)?.round() ?? 0;
      if (!ok || path == null || path.isEmpty) {
        return JewelryProcessResult(
          success: false,
          message: message,
          outputPath: sourcePath,
          usedOriginal: true,
          elapsedMs: DateTime.now().difference(started).inMilliseconds,
        );
      }
      final processedCheck = await _validator.validateFile(path);
      if (!processedCheck.valid) {
        return JewelryProcessResult(
          success: false,
          message:
              'Processed file failed validation. Original recording kept. ${processedCheck.message}',
          outputPath: sourcePath,
          usedOriginal: true,
          elapsedMs: DateTime.now().difference(started).inMilliseconds,
        );
      }
      return JewelryProcessResult(
        success: true,
        message: message,
        outputPath: path,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
        width: width,
        height: height,
      );
    } on MissingPluginException {
      return JewelryProcessResult(
        success: false,
        message:
            'Video processor is not available on this build. Original recording kept.',
        outputPath: sourcePath,
        usedOriginal: true,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    } on PlatformException catch (error) {
      return JewelryProcessResult(
        success: false,
        message: error.message ?? 'Processing failed',
        outputPath: sourcePath,
        usedOriginal: true,
        elapsedMs: DateTime.now().difference(started).inMilliseconds,
      );
    }
  }
}
