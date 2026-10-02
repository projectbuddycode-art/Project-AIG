import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/camera/controllers/capture_controller.dart';
import 'package:aig/features/capture/controllers/capture_orchestrator.dart';
import 'package:aig/features/camera/providers/camera_providers.dart';
import 'package:aig/features/esp32/providers/device_connection_manager_provider.dart';
import 'package:aig/features/esp32/providers/machine_controllers_providers.dart';
import 'package:aig/features/camera/preset_studio/providers/preset_providers.dart';
import 'package:aig/features/gallery/providers/gallery_providers.dart';
import 'package:aig/features/processing/services/jewelry_video_processor.dart';

final captureControllerProvider = Provider<CaptureController>((ref) {
  final camera = ref.read(cameraControllerProvider);
  return camera.capture;
});

final captureOrchestratorProvider = Provider<CaptureOrchestrator>((ref) {
  final machine = ref.read(machineControllerProvider);
  final camera = ref.read(cameraControllerProvider);
  final capture = ref.read(captureControllerProvider);
  final connectionManager = ref.read(deviceConnectionManagerProvider);
  final orchestrator = CaptureOrchestrator(
    machineController: machine,
    cameraController: camera,
    captureController: capture,
    connectionManager: connectionManager,
    diamondCam: ref.read(diamondCamServiceProvider),
    videoProcessor: JewelryVideoProcessor(),
    resolvePreset: (id) => ref.read(presetCatalogProvider.notifier).byId(id),
    onMediaPersisted: (item) =>
        ref.read(galleryListProvider.notifier).addMedia(item),
  );
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

final captureWorkflowStateProvider = StreamProvider((ref) {
  final orchestrator = ref.read(captureOrchestratorProvider);
  return orchestrator.stateStream;
});

final captureWorkflowEventsProvider = StreamProvider((ref) {
  final orchestrator = ref.read(captureOrchestratorProvider);
  return orchestrator.eventStream;
});
