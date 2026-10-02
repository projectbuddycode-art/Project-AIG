import 'package:flutter/foundation.dart';

import 'package:aig/features/export/models/export_progress.dart';
import 'package:aig/features/export/models/export_state.dart';
import 'package:aig/features/export/models/export_task.dart';

@immutable
class ExportJob {
  const ExportJob({
    required this.id,
    required this.task,
    this.state = ExportState.idle,
    this.progress = const ExportProgress(),
    this.priority = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final ExportTask task;
  final ExportState state;
  final ExportProgress progress;
  final int priority;
  final int retryCount;
  final int maxRetries;
  final Map<String, Object?> metadata;

  ExportJob copyWith({
    String? id,
    ExportTask? task,
    ExportState? state,
    ExportProgress? progress,
    int? priority,
    int? retryCount,
    int? maxRetries,
    Map<String, Object?>? metadata,
  }) {
    return ExportJob(
      id: id ?? this.id,
      task: task ?? this.task,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      metadata: metadata ?? this.metadata,
    );
  }
}
