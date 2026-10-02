import 'package:flutter/foundation.dart';

@immutable
class CaptureProgress {
  final int totalSteps;
  final int completedSteps;
  final String currentStepId;

  const CaptureProgress({
    required this.totalSteps,
    required this.completedSteps,
    this.currentStepId = '',
  });

  double get percent => totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

  CaptureProgress copyWith({
    int? totalSteps,
    int? completedSteps,
    String? currentStepId,
  }) {
    return CaptureProgress(
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      currentStepId: currentStepId ?? this.currentStepId,
    );
  }
}
