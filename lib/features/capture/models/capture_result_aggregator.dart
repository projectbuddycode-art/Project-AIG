import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:aig/features/capture/models/capture_step.dart';

@immutable
class CaptureResultAggregator {
  final List<CaptureStepResult> stepResults;

  const CaptureResultAggregator({this.stepResults = const []});

  CaptureResultAggregator add(CaptureStepResult result) {
    return CaptureResultAggregator(stepResults: [...stepResults, result]);
  }

  int get total => stepResults.length;
  int get succeeded => stepResults.where((r) => r.success).length;
  int get failed => stepResults.where((r) => !r.success).length;

  bool get hasFailures => failed > 0;

  List<CaptureStepResult> get results => UnmodifiableListView(stepResults);
}
