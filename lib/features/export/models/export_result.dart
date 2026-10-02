import 'package:flutter/foundation.dart';

import 'package:aig/features/export/models/export_state.dart';

@immutable
class ExportResult {
  const ExportResult({
    required this.state,
    required this.message,
    this.outputPath,
    this.metadata = const <String, Object?>{},
  });

  final ExportState state;
  final String message;
  final String? outputPath;
  final Map<String, Object?> metadata;

  factory ExportResult.success({String? outputPath, Map<String, Object?>? metadata}) {
    return ExportResult(
      state: ExportState.completed,
      message: 'Export completed',
      outputPath: outputPath,
      metadata: metadata ?? const <String, Object?>{},
    );
  }

  factory ExportResult.cancelled({String? message}) {
    return ExportResult(state: ExportState.cancelled, message: message ?? 'Export cancelled');
  }

  factory ExportResult.failed({required String message}) {
    return ExportResult(state: ExportState.failed, message: message);
  }
}
