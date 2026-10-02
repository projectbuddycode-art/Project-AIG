import 'package:flutter/foundation.dart';

import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/models/processing_state.dart';

@immutable
class ProcessingResult {
  final bool success;
  final String message;
  final ProcessingStage stage;
  final ProcessingState state;
  final ProcessingSession session;
  final Map<String, Object?> metadata;
  final bool shouldRetry;

  const ProcessingResult({
    required this.success,
    required this.message,
    required this.stage,
    required this.state,
    required this.session,
    this.metadata = const <String, Object?>{},
    this.shouldRetry = false,
  });

  factory ProcessingResult.success({
    required ProcessingStage stage,
    required ProcessingSession session,
    String message = 'Completed',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => ProcessingResult(
    success: true,
    message: message,
    stage: stage,
    state: ProcessingState.completed,
    session: session,
    metadata: metadata,
  );

  factory ProcessingResult.failure({
    required ProcessingStage stage,
    required ProcessingSession session,
    required String message,
    bool shouldRetry = false,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) => ProcessingResult(
    success: false,
    message: message,
    stage: stage,
    state: ProcessingState.failed,
    session: session,
    metadata: metadata,
    shouldRetry: shouldRetry,
  );

  factory ProcessingResult.cancelled({
    required ProcessingStage stage,
    required ProcessingSession session,
    String message = 'Cancelled',
  }) => ProcessingResult(
    success: false,
    message: message,
    stage: stage,
    state: ProcessingState.cancelled,
    session: session,
  );
}
