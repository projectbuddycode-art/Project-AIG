import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class PresetValidation {
  const PresetValidation();

  String? validate(CameraPreset preset) {
    if (preset.id.trim().isEmpty) {
      return 'Preset id is required';
    }
    if (preset.name.trim().isEmpty) {
      return 'Preset name is required';
    }
    if (preset.captureDurationSeconds < 1 ||
        preset.captureDurationSeconds > 60) {
      return 'Recording duration must be between 1 and 60 seconds';
    }
    if (preset.machineSpeed < 1 || preset.machineSpeed > 100) {
      return 'Machine speed must be between 1 and 100';
    }
    if (preset.lightIntensity < 0 || preset.lightIntensity > 100) {
      return 'Light intensity must be between 0 and 100';
    }
    if (preset.rotationDirection != 'cw' && preset.rotationDirection != 'ccw') {
      return 'Rotation direction must be cw or ccw';
    }
    if (preset.frameRate != 24 && preset.frameRate != 30) {
      return 'Frame rate must be 24 or 30';
    }
    if (preset.filterStrength < 0 || preset.filterStrength > 100) {
      return 'Filter strength must be between 0 and 100';
    }
    return null;
  }
}
