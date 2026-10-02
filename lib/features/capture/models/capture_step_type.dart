/// Types of capture steps within a workflow.
enum CaptureStepType {
  initialize,
  validate,
  configureMachine,
  configureCamera,
  stabilize,
  capture,
  process,
  complete,
}

extension CaptureStepTypeX on CaptureStepType {
  String get name {
    switch (this) {
      case CaptureStepType.initialize:
        return 'Initialize';
      case CaptureStepType.validate:
        return 'Validate';
      case CaptureStepType.configureMachine:
        return 'Configure Machine';
      case CaptureStepType.configureCamera:
        return 'Configure Camera';
      case CaptureStepType.stabilize:
        return 'Stabilize';
      case CaptureStepType.capture:
        return 'Capture';
      case CaptureStepType.process:
        return 'Process';
      case CaptureStepType.complete:
        return 'Complete';
    }
  }
}
