import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class VideoCapturePreset extends CameraPreset {
  const VideoCapturePreset({
    required super.id,
    required super.name,
    required super.description,
    super.advertisingPurpose,
    super.cameraConfig,
    super.lightingConfig,
    super.rotationConfig,
    super.captureDurationSeconds,
    super.processingPipeline,
    super.exportDefaults,
    super.requiresMachine,
    super.rotationMode,
    super.rotationDirection,
    super.machineSpeed,
    super.machineAngle,
    super.lightOn,
    super.lightIntensity,
    super.aspectRatio,
    super.frameRate,
    super.resolutionLabel,
    super.processingLook,
    super.isCustom,
  }) : super(isVideoPreset: true);
}
