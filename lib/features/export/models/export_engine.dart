import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_result.dart';
import 'package:aig/features/export/models/export_session.dart';
import 'package:aig/features/export/models/export_task.dart';

class ExportEngine {
  Future<ExportResult> export(ExportSession session, ExportTask task) async {
    final configuration = session.configuration;
    final sourcePath = session.metadata['sourceFilePath'] as String? ?? configuration.metadata['sourceFilePath'] as String?;
    if (sourcePath == null || sourcePath.isEmpty) {
      return ExportResult.failed(message: 'No source file available for export');
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return ExportResult.failed(message: 'Source file no longer exists');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory('${directory.path}/exports');
      await exportDirectory.create(recursive: true);
      final outputPath = _buildOutputPath(configuration, session.id, exportDirectory.path);
      final outputFile = File(outputPath);
      final bytes = await sourceFile.readAsBytes();
      if (bytes.isEmpty) {
        return ExportResult.failed(message: 'Source file is empty');
      }
      await outputFile.writeAsBytes(bytes);
      if (!outputFile.existsSync() || outputFile.lengthSync() <= 0) {
        return ExportResult.failed(message: 'Export wrote an empty file');
      }

      return ExportResult.success(
        outputPath: outputFile.path,
        metadata: <String, Object?>{
          'format': configuration.format.name,
          'destination': configuration.destination.name,
          'sourcePath': sourcePath,
          'sizeBytes': bytes.length,
          'quality': configuration.quality,
          'compression': configuration.compression,
        },
      );
    } catch (error) {
      return ExportResult.failed(message: 'Export failed: $error');
    }
  }

  String _buildOutputPath(ExportConfiguration configuration, String sessionId, String directory) {
    final extension = switch (configuration.format) {
      ExportFormat.jpeg => 'jpg',
      ExportFormat.png => 'png',
      ExportFormat.raw => 'raw',
      ExportFormat.heif => 'heif',
      ExportFormat.tiff => 'tiff',
      ExportFormat.mp4 => 'mp4',
      ExportFormat.mov => 'mov',
    };

    return '$directory/${configuration.filename}_$sessionId.$extension';
  }
}
