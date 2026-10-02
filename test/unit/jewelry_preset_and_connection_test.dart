import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/preset_studio/services/preset_workflow_planner.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/processing/services/jewelry_video_validator.dart';
import 'package:aig/features/processing/services/jewelry_video_processor.dart';
import 'package:flutter/services.dart';

void main() {
  test('verified DiamondCam phase maps to protocol-verified connection', () {
    const diamond = DiamondCamUiState(phase: DiamondCamPhase.verified);
    final mapped = deviceConnectionFromDiamondCam(diamond);
    expect(mapped.status, ConnectionStatus.connected);
    expect(connectionStatusLabel(mapped.status), 'Protocol Verified');
  });

  test('reachable DiamondCam is not shown as connected', () {
    const diamond = DiamondCamUiState(phase: DiamondCamPhase.reachable);
    final mapped = deviceConnectionFromDiamondCam(diamond);
    expect(mapped.status, isNot(ConnectionStatus.connected));
    expect(mapped.status, ConnectionStatus.connectedUnverified);
  });

  test('disconnected DiamondCam can keep a managed verified state', () {
    const diamond = DiamondCamUiState(phase: DiamondCamPhase.disconnected);
    final managed = DeviceConnectionState.connected('ESP32 Machine', 0);
    final resolved = resolveMachineConnection(diamond, managed);
    expect(resolved.status, ConnectionStatus.connected);
  });

  test(
    'every advertising preset has distinct processing or machine settings',
    () {
      const manager = PresetManager();
      final presets = manager.builtInPresets;
      expect(presets.length, greaterThanOrEqualTo(11));
      final signatures = presets.map((preset) {
        return '${preset.id}|${preset.processingLook}|${preset.aspectRatio}|${preset.machineSpeed}|${preset.captureDurationSeconds}|${preset.rotationDirection}|${preset.lightIntensity}';
      }).toSet();
      expect(signatures.length, presets.length);
      expect(
        presets.any((preset) => preset.id == 'diamond-luxury-360'),
        isTrue,
      );
      expect(
        presets.any((preset) => preset.id == 'custom-advertising'),
        isTrue,
      );
    },
  );

  test('machine presets generate lighting and rotation command bodies', () {
    const manager = PresetManager();
    const planner = PresetWorkflowPlanner();
    final preset = manager.getPreset('luxury-dark-studio');
    final plan = planner.plan(
      preset: preset,
      cameraReady: true,
      machineVerified: true,
      isVideo: true,
    );
    expect(plan.canExecute, isTrue);
    final lighting = plan.steps.firstWhere(
      (step) => step.id == PresetWorkflowStepId.applyLighting,
    );
    expect(lighting.body?['state'], isTrue);
    expect(lighting.body?['intensity'], preset.lightIntensity);
    final rotation = plan.steps.firstWhere(
      (step) => step.id == PresetWorkflowStepId.startRotation,
    );
    expect(rotation.body?['path'], '/rotate/continuous');
    expect(rotation.body?['direction'], 'cw');
    expect(
      plan.steps.any((step) => step.id == PresetWorkflowStepId.stopMotor),
      isTrue,
    );
    expect(
      plan.steps.any((step) => step.id == PresetWorkflowStepId.processVideo),
      isTrue,
    );
  });

  test('machine-required preset is blocked when protocol is unverified', () {
    const manager = PresetManager();
    const planner = PresetWorkflowPlanner();
    final plan = planner.plan(
      preset: manager.getPreset('full-360-showcase'),
      cameraReady: true,
      machineVerified: false,
      isVideo: true,
    );
    expect(plan.canExecute, isFalse);
    expect(plan.blockedReason, contains('protocol-verified'));
  });

  test('camera-only preset can run without a machine', () {
    const manager = PresetManager();
    const planner = PresetWorkflowPlanner();
    final plan = planner.plan(
      preset: manager.getPreset('white-background'),
      cameraReady: true,
      machineVerified: false,
      isVideo: false,
    );
    expect(plan.canExecute, isTrue);
    expect(
      plan.steps.any((step) => step.id == PresetWorkflowStepId.startRotation),
      isFalse,
    );
  });

  test('invalid MP4 is rejected and missing files fail closed', () async {
    const validator = JewelryVideoValidator();
    final missing = await validator.validateFile(
      'C:/definitely-missing-aig.mp4',
    );
    expect(missing.valid, isFalse);

    final temp = File(
      '${Directory.systemTemp.path}/aig_bad_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    await temp.writeAsBytes(Uint8List.fromList(List<int>.filled(9000, 1)));
    addTearDown(() => temp.deleteSync());
    final invalid = await validator.validateFile(temp.path);
    expect(invalid.valid, isFalse);
    expect(invalid.message, contains('ftyp'));
  });

  test('valid ftyp header is accepted', () async {
    const validator = JewelryVideoValidator();
    final temp = File(
      '${Directory.systemTemp.path}/aig_ok_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final bytes = Uint8List(9000);
    bytes[4] = 0x66;
    bytes[5] = 0x74;
    bytes[6] = 0x79;
    bytes[7] = 0x70;
    await temp.writeAsBytes(bytes);
    addTearDown(() => temp.deleteSync());
    final valid = await validator.validateFile(temp.path);
    expect(valid.valid, isTrue);
  });

  test(
    'processor keeps original when platform processing is unavailable',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('aig.camera/methods');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => throw PlatformException(
              code: 'missing',
              message: 'processor missing',
            ),
          );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final temp = File(
        '${Directory.systemTemp.path}/aig_src_${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      final bytes = Uint8List(9000);
      bytes[4] = 0x66;
      bytes[5] = 0x74;
      bytes[6] = 0x79;
      bytes[7] = 0x70;
      await temp.writeAsBytes(bytes);
      addTearDown(() => temp.deleteSync());

      final processor = JewelryVideoProcessor(channel: channel);
      final result = await processor.process(
        sourcePath: temp.path,
        preset: const PresetManager().getPreset('luxury-dark-studio'),
      );
      expect(result.outputPath, temp.path);
      expect(result.usedOriginal, isTrue);
    },
  );
}
