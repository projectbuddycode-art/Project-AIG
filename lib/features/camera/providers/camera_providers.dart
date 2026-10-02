import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/engines/flutter_camera_engine.dart';
import 'package:aig/features/camera/engines/platform_camera_engine.dart';
import 'package:aig/features/camera/controllers/camera_controller.dart';
import 'package:aig/features/camera/controllers/camera_state_controller.dart';
import 'package:aig/features/camera/models/camera_state.dart';
import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/esp32/providers/machine_controllers_providers.dart';

final cameraEngineProvider = Provider<CameraEngine>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformCameraEngine();
  }
  return FlutterCameraEngine();
});

final cameraStateNotifierProvider =
    StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
      return CameraStateNotifier();
    });

final cameraControllerProvider = Provider<CameraController>((ref) {
  final engine = ref.read(cameraEngineProvider);
  final machine = ref.read(machineControllerProvider);
  return CameraController(engine, machine);
});

final jewelryLookPreviewProvider = StateProvider<JewelryLookPreview>((ref) {
  return const JewelryLookPreview(look: JewelryProcessingLook.luxuryDark);
});
