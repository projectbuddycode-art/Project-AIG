import 'package:flutter/foundation.dart';

import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/models/capture_progress.dart';
import 'package:aig/features/capture/models/capture_workflow_stage.dart';

@immutable
class CaptureWorkflowState {
  final CaptureWorkflowStage stage;
  final bool isRunning;
  final bool isPaused;
  final bool isCancelled;
  final bool hasFailed;
  final CaptureMode mode;
  final String currentStep;
  final String message;
  final CaptureProgress progress;

  const CaptureWorkflowState({
    required this.stage,
    required this.isRunning,
    required this.isPaused,
    required this.isCancelled,
    required this.hasFailed,
    required this.mode,
    required this.currentStep,
    required this.message,
    required this.progress,
  });

  factory CaptureWorkflowState.initial(CaptureMode mode) =>
      CaptureWorkflowState(
        stage: CaptureWorkflowStage.idle,
        isRunning: false,
        isPaused: false,
        isCancelled: false,
        hasFailed: false,
        mode: mode,
        currentStep: '',
        message: '',
        progress: const CaptureProgress(totalSteps: 0, completedSteps: 0),
      );

  CaptureWorkflowState copyWith({
    CaptureWorkflowStage? stage,
    bool? isRunning,
    bool? isPaused,
    bool? isCancelled,
    bool? hasFailed,
    CaptureMode? mode,
    String? currentStep,
    String? message,
    CaptureProgress? progress,
  }) {
    return CaptureWorkflowState(
      stage: stage ?? this.stage,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isCancelled: isCancelled ?? this.isCancelled,
      hasFailed: hasFailed ?? this.hasFailed,
      mode: mode ?? this.mode,
      currentStep: currentStep ?? this.currentStep,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}
