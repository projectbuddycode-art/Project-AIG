import 'package:flutter/foundation.dart';

import 'package:aig/features/capture/models/capture_step_type.dart';

@immutable
class CaptureStepDetail {
  final String id;
  final CaptureStepType type;
  final String machineAction;
  final String cameraAction;
  final Duration delayBefore;
  final Duration delayAfter;
  final String completionCondition;

  const CaptureStepDetail({
    required this.id,
    required this.type,
    this.machineAction = '',
    this.cameraAction = '',
    this.delayBefore = Duration.zero,
    this.delayAfter = Duration.zero,
    this.completionCondition = '',
  });
}
