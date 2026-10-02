/// Explicit workflow stages for the capture orchestrator.
enum CaptureWorkflowStage {
  idle,
  preparing,
  validating,
  configuringMachine,
  configuringCamera,
  waitingForStabilization,
  capturing,
  capturingPhoto,
  startingVideo,
  recordingVideo,
  stoppingVideo,
  savingMedia,
  processing,
  verifyingOutput,
  completed,
  cancelled,
  failed,
}

String captureWorkflowStageLabel(
  CaptureWorkflowStage? stage, {
  String fallback = 'Ready',
}) {
  switch (stage) {
    case CaptureWorkflowStage.idle:
      return 'Idle';
    case CaptureWorkflowStage.preparing:
      return 'Preparing';
    case CaptureWorkflowStage.validating:
      return 'Validating';
    case CaptureWorkflowStage.configuringMachine:
      return 'Configuring Machine';
    case CaptureWorkflowStage.configuringCamera:
      return 'Configuring Camera';
    case CaptureWorkflowStage.waitingForStabilization:
      return 'Waiting For Stabilization';
    case CaptureWorkflowStage.capturing:
      return 'Capturing';
    case CaptureWorkflowStage.capturingPhoto:
      return 'Capturing photo';
    case CaptureWorkflowStage.startingVideo:
      return 'Starting recording';
    case CaptureWorkflowStage.recordingVideo:
      return 'Recording';
    case CaptureWorkflowStage.stoppingVideo:
      return 'Stopping recording';
    case CaptureWorkflowStage.savingMedia:
      return 'Saving';
    case CaptureWorkflowStage.processing:
      return 'Processing';
    case CaptureWorkflowStage.verifyingOutput:
      return 'Verifying output';
    case CaptureWorkflowStage.completed:
      return 'Ready to export';
    case CaptureWorkflowStage.cancelled:
      return 'Cancelled';
    case CaptureWorkflowStage.failed:
      return 'Failed';
    case null:
      return fallback;
  }
}

extension CaptureWorkflowStageX on CaptureWorkflowStage {
  String get label => captureWorkflowStageLabel(this, fallback: 'Ready');
}
