import 'package:flutter_test/flutter_test.dart';
import 'package:aig/features/capture/controllers/capture_orchestrator.dart';
import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/controllers/rotation_controller.dart';
import 'package:aig/features/esp32/controllers/lighting_controller.dart';
import 'package:aig/features/esp32/controllers/preset_controller.dart';
import 'package:aig/features/esp32/controllers/machine_status_controller.dart';
import 'package:aig/features/esp32/controllers/safety_controller.dart';
import 'package:aig/features/esp32/services/command_executor.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/camera/controllers/camera_controller.dart';
import 'package:aig/features/camera/controllers/capture_controller.dart';
import 'package:aig/features/capture/models/capture_session.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/models/capture_workflow_stage.dart';
import 'package:aig/features/esp32/models/device_info.dart';
import '../mocks/mock_device_transport.dart';
import '../mocks/mock_camera_engine.dart';

MachineController makeFakeMachineController(MockDeviceTransport transport) {
  final protocol = const DeviceProtocol();
  final logger = const DeviceLogger();
  final executor = CommandExecutor(
    transport: transport,
    protocol: protocol,
    logger: logger,
    timeout: const Duration(milliseconds: 200),
  );

  final rotation = RotationController(executor);
  final lighting = LightingController(executor);
  final presets = PresetController(executor);
  final status = MachineStatusController(executor);
  final safety = SafetyController(executor, rotation);

  return MachineController(
    rotation: rotation,
    lighting: lighting,
    presets: presets,
    status: status,
    safety: safety,
  );
}

class _FakeCaptureController extends CaptureController {
  _FakeCaptureController(super.engine);
}

void main() {
  test('CaptureOrchestrator completes a simple session with mocks', () async {
    final transport = MockDeviceTransport();
    final logger = const DeviceLogger();
    final connectionManager = DeviceConnectionManager(
      transport: transport,
      logger: logger,
    );

    // simulate connected state
    final device = DeviceInfo(id: 'mock-1', name: 'MockDevice', rssi: -40);
    await connectionManager.connect(device);

    final mockEngine = MockCameraEngine();
    final fakeMachine = makeFakeMachineController(transport);
    final cameraController = CameraController(mockEngine, fakeMachine);
    final captureController = _FakeCaptureController(mockEngine);

    final orchestrator = CaptureOrchestrator(
      machineController: fakeMachine,
      connectionManager: connectionManager,
      cameraController: cameraController,
      captureController: captureController,
    );

    // allow connection manager to reach connected state
    await Future<void>.delayed(Duration(milliseconds: 100));

    final session = CaptureSession(id: 'test', mode: CaptureMode.singlePhoto);

    final events = <dynamic>[];
    final sub = orchestrator.eventStream.listen((e) => events.add(e));

    await orchestrator.startSession(session);
    await Future<void>.delayed(Duration(seconds: 1));

    expect(events.any((e) => e.id == 'completed'), true);
    expect(orchestrator.latestCapturedFilePath, isNotNull);
    expect(orchestrator.latestMediaStoreUri, isNotNull);
    expect(orchestrator.latestMediaStoreUri, isNotEmpty);

    await sub.cancel();
    orchestrator.dispose();
    connectionManager.dispose();
  }, timeout: Timeout(Duration(seconds: 10)));

  test(
    'CaptureOrchestrator ignores duplicate session starts to prevent duplicate captures',
    () async {
      final transport = MockDeviceTransport();
      final logger = const DeviceLogger();
      final connectionManager = DeviceConnectionManager(
        transport: transport,
        logger: logger,
      );
      final device = DeviceInfo(id: 'mock-2', name: 'MockDevice', rssi: -40);
      await connectionManager.connect(device);

      final mockEngine = MockCameraEngine();
      final fakeMachine = makeFakeMachineController(transport);
      final cameraController = CameraController(mockEngine, fakeMachine);
      final captureController = _FakeCaptureController(mockEngine);

      final orchestrator = CaptureOrchestrator(
        machineController: fakeMachine,
        connectionManager: connectionManager,
        cameraController: cameraController,
        captureController: captureController,
      );

      await Future<void>.delayed(Duration(milliseconds: 100));

      final session = CaptureSession(
        id: 'duplicate-test',
        mode: CaptureMode.singlePhoto,
      );
      final completedEvents = <dynamic>[];
      final sub = orchestrator.eventStream.listen((event) {
        if (event.id == 'completed') completedEvents.add(event);
      });

      await Future.wait([
        orchestrator.startSession(session),
        orchestrator.startSession(session),
      ]);
      await Future<void>.delayed(Duration(seconds: 1));

      expect(completedEvents, isNotEmpty);
      expect(completedEvents, hasLength(1));

      await sub.cancel();
      orchestrator.dispose();
      connectionManager.dispose();
    },
    timeout: Timeout(Duration(seconds: 10)),
  );

  test(
    'Capture workflow stage labels resolve safely without extension getter crashes',
    () {
      expect(
        captureWorkflowStageLabel(CaptureWorkflowStage.capturing),
        'Capturing',
      );
      expect(
        captureWorkflowStageLabel(CaptureWorkflowStage.completed),
        'Ready to export',
      );
      expect(captureWorkflowStageLabel(null), 'Ready');
    },
  );
}
