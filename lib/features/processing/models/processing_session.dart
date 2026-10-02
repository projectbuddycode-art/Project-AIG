import 'package:flutter/foundation.dart';

import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/models/processing_state.dart';

@immutable
class ProcessingSession {
  final String id;
  final String sourceMediaId;
  final String? outputMediaId;
  final List<ProcessingStage> appliedStages;
  final ProcessingStage? currentStage;
  final double progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> errors;
  final Map<String, Object?> metadata;
  final ProcessingState state;

  const ProcessingSession({
    required this.id,
    required this.sourceMediaId,
    this.outputMediaId,
    this.appliedStages = const <ProcessingStage>[],
    this.currentStage,
    this.progress = 0.0,
    this.startedAt,
    this.completedAt,
    this.errors = const <String>[],
    this.metadata = const <String, Object?>{},
    this.state = ProcessingState.idle,
  });

  ProcessingSession copyWith({
    String? id,
    String? sourceMediaId,
    String? outputMediaId,
    List<ProcessingStage>? appliedStages,
    ProcessingStage? currentStage,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? errors,
    Map<String, Object?>? metadata,
    ProcessingState? state,
  }) {
    return ProcessingSession(
      id: id ?? this.id,
      sourceMediaId: sourceMediaId ?? this.sourceMediaId,
      outputMediaId: outputMediaId ?? this.outputMediaId,
      appliedStages: appliedStages ?? this.appliedStages,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errors: errors ?? this.errors,
      metadata: metadata ?? this.metadata,
      state: state ?? this.state,
    );
  }
}
