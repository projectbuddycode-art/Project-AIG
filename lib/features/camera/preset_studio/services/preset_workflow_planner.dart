import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

enum PresetWorkflowStepId {
  validatePreset,
  validateCamera,
  validateMachine,
  applyLighting,
  startRotation,
  startRecording,
  waitDuration,
  stopRecording,
  stopMotor,
  finalizeMedia,
  processVideo,
  complete,
}

class PresetWorkflowStep {
  const PresetWorkflowStep({
    required this.id,
    required this.label,
    this.requiresMachine = false,
    this.body,
  });

  final PresetWorkflowStepId id;
  final String label;
  final bool requiresMachine;
  final Map<String, Object?>? body;
}

class PresetWorkflowPlan {
  const PresetWorkflowPlan({
    required this.presetId,
    required this.steps,
    required this.requiresMachine,
    this.blockedReason,
  });

  final String presetId;
  final List<PresetWorkflowStep> steps;
  final bool requiresMachine;
  final String? blockedReason;

  bool get canExecute => blockedReason == null;
}

class PresetWorkflowPlanner {
  const PresetWorkflowPlanner();

  PresetWorkflowPlan plan({
    required CameraPreset preset,
    required bool cameraReady,
    required bool machineVerified,
    required bool isVideo,
  }) {
    if (preset.id.trim().isEmpty) {
      return PresetWorkflowPlan(
        presetId: preset.id,
        steps: const [],
        requiresMachine: preset.requiresMachine,
        blockedReason: 'Preset id is missing',
      );
    }
    if (!cameraReady) {
      return PresetWorkflowPlan(
        presetId: preset.id,
        steps: const [],
        requiresMachine: preset.requiresMachine,
        blockedReason: 'Camera is not ready',
      );
    }
    final needsMotion =
        preset.requiresMachine &&
        (preset.rotationMode != MachineRotationMode.none ||
            preset.rotationConfig.autoRotate);
    if (needsMotion && !machineVerified) {
      return PresetWorkflowPlan(
        presetId: preset.id,
        steps: const [],
        requiresMachine: true,
        blockedReason:
            'This preset needs a protocol-verified machine. Connect DiamondCam, then try again.',
      );
    }

    final steps = <PresetWorkflowStep>[
      const PresetWorkflowStep(
        id: PresetWorkflowStepId.validatePreset,
        label: 'Validate preset',
      ),
      const PresetWorkflowStep(
        id: PresetWorkflowStepId.validateCamera,
        label: 'Validate camera',
      ),
    ];
    if (needsMotion || (preset.lightOn && machineVerified)) {
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.validateMachine,
          label: 'Validate machine',
          requiresMachine: true,
        ),
      );
      steps.add(
        PresetWorkflowStep(
          id: PresetWorkflowStepId.applyLighting,
          label: 'Apply lighting',
          requiresMachine: true,
          body: {
            'state': preset.lightOn,
            'intensity': preset.lightIntensity.clamp(0, 100),
          },
        ),
      );
    }
    if (needsMotion && machineVerified) {
      if (preset.rotationMode == MachineRotationMode.angle &&
          preset.machineAngle != null) {
        steps.add(
          PresetWorkflowStep(
            id: PresetWorkflowStepId.startRotation,
            label: 'Move to angle',
            requiresMachine: true,
            body: {
              'path': '/rotate',
              'angle': preset.machineAngle!.clamp(0, 180),
              'speed': preset.machineSpeed.clamp(1, 100),
            },
          ),
        );
      } else {
        steps.add(
          PresetWorkflowStep(
            id: PresetWorkflowStepId.startRotation,
            label: 'Start rotation',
            requiresMachine: true,
            body: {
              'path': '/rotate/continuous',
              'direction': preset.rotationDirection == 'ccw' ? 'ccw' : 'cw',
              'speed': preset.machineSpeed.clamp(1, 100),
            },
          ),
        );
      }
    }
    if (isVideo) {
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.startRecording,
          label: 'Start recording',
        ),
      );
      if (preset.captureDurationSeconds > 0) {
        steps.add(
          PresetWorkflowStep(
            id: PresetWorkflowStepId.waitDuration,
            label: 'Record ${preset.captureDurationSeconds}s',
            body: {'seconds': preset.captureDurationSeconds},
          ),
        );
      }
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.stopRecording,
          label: 'Stop recording',
        ),
      );
      if (needsMotion) {
        steps.add(
          const PresetWorkflowStep(
            id: PresetWorkflowStepId.stopMotor,
            label: 'Stop motor',
            requiresMachine: true,
            body: {'path': '/rotate/stop'},
          ),
        );
      }
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.finalizeMedia,
          label: 'Finalize media',
        ),
      );
      steps.add(
        PresetWorkflowStep(
          id: PresetWorkflowStepId.processVideo,
          label: 'Process video',
          body: {
            'look': preset.processingLook.name,
            'aspectRatio': preset.aspectRatio,
          },
        ),
      );
    } else {
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.startRecording,
          label: 'Capture photo',
        ),
      );
      steps.add(
        const PresetWorkflowStep(
          id: PresetWorkflowStepId.finalizeMedia,
          label: 'Finalize media',
        ),
      );
    }
    steps.add(
      const PresetWorkflowStep(
        id: PresetWorkflowStepId.complete,
        label: 'Complete',
      ),
    );
    return PresetWorkflowPlan(
      presetId: preset.id,
      steps: steps,
      requiresMachine: needsMotion,
    );
  }
}
