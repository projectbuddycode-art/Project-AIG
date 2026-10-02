import 'package:flutter/foundation.dart';

import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_progress.dart';
import 'package:aig/features/export/models/export_state.dart';

@immutable
class ExportSession {
  const ExportSession({
    required this.id,
    this.sourceMediaId,
    this.outputPath,
    this.state = ExportState.idle,
    this.progress = const ExportProgress(),
    this.configuration = const ExportConfiguration(),
    this.errors = const <String>[],
    this.startedAt,
    this.completedAt,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String? sourceMediaId;
  final String? outputPath;
  final ExportState state;
  final ExportProgress progress;
  final ExportConfiguration configuration;
  final List<String> errors;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, Object?> metadata;

  ExportSession copyWith({
    String? id,
    String? sourceMediaId,
    String? outputPath,
    ExportState? state,
    ExportProgress? progress,
    ExportConfiguration? configuration,
    List<String>? errors,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, Object?>? metadata,
  }) {
    return ExportSession(
      id: id ?? this.id,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      outputPath: outputPath ?? this.outputPath,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      configuration: configuration ?? this.configuration,
      errors: errors ?? this.errors,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
