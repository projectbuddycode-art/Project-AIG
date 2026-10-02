/// Supported capture modes for the workflow.
enum CaptureMode {
  singlePhoto,
  burstPhotos,
  photo360,
  video360,
  presetCapture,
  timelapse,
  macroSequence,
}

extension CaptureModeX on CaptureMode {
  bool get isPhoto =>
      this == CaptureMode.singlePhoto ||
      this == CaptureMode.burstPhotos ||
      this == CaptureMode.photo360 ||
      this == CaptureMode.presetCapture ||
      this == CaptureMode.macroSequence;
  bool get isVideo =>
      this == CaptureMode.video360 || this == CaptureMode.timelapse;
}
