import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';

/// MediaStorePublisher handles publishing captured media to Android MediaStore.
/// Ensures files appear in the device's Photos/Videos apps.
class MediaStorePublisher {
  static const MethodChannel _channel = MethodChannel('aig.camera/methods');

  /// Publish a photo to Android MediaStore and device gallery.
  ///
  /// Copies the file from app documents to Pictures/AIG collection
  /// so it appears in the device's Photos app.
  static Future<String?> publishPhoto(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!sourceFile.existsSync()) {
        developer.log(
          'ERROR: Photo file not found: $filePath',
          name: 'MediaStorePublisher',
        );
        return null;
      }

      // Ensure file has content
      final size = await sourceFile.length();
      if (size == 0) {
        developer.log(
          'ERROR: Photo file is empty (0 bytes): $filePath',
          name: 'MediaStorePublisher',
        );
        return null;
      }

      final result = await _publish(sourceFile.path, 'photo');
      developer.log(
        'Photo published to MediaStore: ${result ?? 'failed'}',
        name: 'MediaStorePublisher',
      );
      return result;
    } catch (e) {
      developer.log(
        'ERROR: Failed to publish photo: $e',
        name: 'MediaStorePublisher',
      );
      return null;
    }
  }

  /// Publish a video to Android MediaStore and device gallery.
  ///
  /// Copies the file from app cache to Movies/AIG collection
  /// so it appears in the device's Videos app.
  static Future<String?> publishVideo(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!sourceFile.existsSync()) {
        developer.log(
          'ERROR: Video file not found: $filePath',
          name: 'MediaStorePublisher',
        );
        return null;
      }

      // Ensure file has content (MP4 should be > 0 bytes)
      // Note: Short videos may be < 1MB; we only require that the file exists and has content
      final size = await sourceFile.length();
      if (size == 0) {
        developer.log(
          'ERROR: Video file is empty (0 bytes): $filePath',
          name: 'MediaStorePublisher',
        );
        return null;
      }

      final result = await _publish(sourceFile.path, 'video');
      developer.log(
        'Video published to MediaStore: $result ($size bytes)',
        name: 'MediaStorePublisher',
      );
      return result;
    } catch (e) {
      developer.log(
        'ERROR: Failed to publish video: $e',
        name: 'MediaStorePublisher',
      );
      return null;
    }
  }

  static Future<String?> _publish(String sourcePath, String mediaType) async {
    try {
      final extension = mediaType == 'video' ? 'mp4' : 'jpg';
      final displayName =
          'AIG_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'publishToMediaStore',
        <String, dynamic>{
          'sourcePath': sourcePath,
          'mediaType': mediaType,
          'displayName': displayName,
        },
      );
      final uri = result?['uri'] as String?;
      final size = (result?['size'] as num?)?.toInt() ?? 0;
      if (uri == null || uri.isEmpty || size <= 0) return null;
      return uri;
    } on PlatformException catch (error) {
      developer.log(
        'MediaStore insertion failed: ${error.message}',
        name: 'MediaStorePublisher',
      );
      return null;
    }
  }

  /// Validate that a captured file is ready for gallery storage.
  static Future<bool> validateCaptureFile(
    String filePath,
    String mediaType,
  ) async {
    try {
      final file = File(filePath);

      // File must exist
      if (!file.existsSync()) {
        developer.log(
          'VALIDATE: File does not exist',
          name: 'MediaStorePublisher',
        );
        return false;
      }

      // File must have content
      final size = await file.length();
      if (size == 0) {
        developer.log('VALIDATE: File is empty', name: 'MediaStorePublisher');
        return false;
      }

      if (mediaType == 'photo') {
        // JPEG files must start with FF D8 magic bytes
        final bytes = await file.readAsBytes();
        if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
          developer.log(
            'VALIDATE: Not a valid JPEG file',
            name: 'MediaStorePublisher',
          );
          return false;
        }
        developer.log(
          '✓ VALIDATE: JPEG is valid ($size bytes)',
          name: 'MediaStorePublisher',
        );
      } else if (mediaType == 'video') {
        // MP4 files must exist and have content
        // Note: Short videos may be < 1MB; we only require that the file exists and has content
        if (size == 0) {
          developer.log(
            'VALIDATE: Video file is empty',
            name: 'MediaStorePublisher',
          );
          return false;
        }
        developer.log(
          '✓ VALIDATE: MP4 is valid ($size bytes)',
          name: 'MediaStorePublisher',
        );
      }

      return true;
    } catch (e) {
      developer.log('VALIDATE ERROR: $e', name: 'MediaStorePublisher');
      return false;
    }
  }
}
