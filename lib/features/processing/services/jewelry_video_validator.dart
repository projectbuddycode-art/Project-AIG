import 'dart:io';
import 'dart:typed_data';

class VideoValidationResult {
  const VideoValidationResult({
    required this.valid,
    required this.message,
    this.sizeBytes = 0,
    this.hasFtyp = false,
  });

  final bool valid;
  final String message;
  final int sizeBytes;
  final bool hasFtyp;
}

class JewelryVideoValidator {
  const JewelryVideoValidator();

  Future<VideoValidationResult> validateFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return const VideoValidationResult(
        valid: false,
        message: 'Source video is missing',
      );
    }
    final size = await file.length();
    if (size < 8192) {
      return VideoValidationResult(
        valid: false,
        message: 'Source video is too small to be a finished MP4 ($size bytes)',
        sizeBytes: size,
      );
    }
    final handle = await file.open();
    try {
      final header = await handle.read(64);
      final hasFtyp = _containsFtyp(header);
      if (!hasFtyp) {
        return VideoValidationResult(
          valid: false,
          message: 'Source file is not a decodable MP4 (missing ftyp)',
          sizeBytes: size,
        );
      }
      return VideoValidationResult(
        valid: true,
        message: 'Source video is valid',
        sizeBytes: size,
        hasFtyp: true,
      );
    } finally {
      await handle.close();
    }
  }

  bool _containsFtyp(List<int> bytes) {
    if (bytes.length < 8) {
      return false;
    }
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    for (var i = 0; i <= data.length - 4; i++) {
      if (data[i] == 0x66 &&
          data[i + 1] == 0x74 &&
          data[i + 2] == 0x79 &&
          data[i + 3] == 0x70) {
        return true;
      }
    }
    return false;
  }
}
