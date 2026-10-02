import 'package:flutter/foundation.dart';

import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/models/capture_step.dart';

/// A capture sequence is an ordered set of steps per workflow mode.
@immutable
class CaptureSequence {
  final CaptureMode mode;
  final List<CaptureStep> steps;

  const CaptureSequence({required this.mode, required this.steps});

  int get totalSteps => steps.length;

  CaptureStep? getStepAt(int index) =>
      index >= 0 && index < steps.length ? steps[index] : null;
}
