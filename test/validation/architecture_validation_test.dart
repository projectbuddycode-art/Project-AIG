import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/camera/controllers/camera_controller.dart';
import 'package:aig/features/capture/controllers/capture_orchestrator.dart';
import 'package:aig/features/capture/models/capture_session.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/esp32/models/device_info.dart';

import '../mocks/fake_machine_controller.dart';
import '../mocks/mock_device_transport.dart';
import '../mocks/mock_camera_engine.dart';

void main() {
  test('Full mocked application flow architecture validation', () async {
    final transport = MockDeviceTransport();
    final logger = const DeviceLogger();
    final connectionManager = DeviceConnectionManager(transport: transport, logger: logger);

    final machine = makeFakeMachineController(transport);
    final engine = MockCameraEngine();
    final cameraController = CameraController(engine, machine);
    final captureController = cameraController.capture;

    final orchestrator = CaptureOrchestrator(
      machineController: machine,
      connectionManager: connectionManager,
      cameraController: cameraController,
      captureController: captureController,
    );

    // Monitor streams and closures
    var connectionDone = false;
    final connStates = <String>[];
    final connSub = connectionManager.state.listen((s) { connStates.add(s.status.name); }, onDone: () => connectionDone = true);

    var previewDone = false;
    final frameCompleter = Completer<dynamic>();
    final prevSub = cameraController.preview.listen((f) {
      if (!frameCompleter.isCompleted) frameCompleter.complete(f);
    }, onDone: () => previewDone = true);

    var events = <String>[];
    var eventsDone = false;
    final evtSub = orchestrator.eventStream.listen((e) { events.add(e.id); }, onDone: () => eventsDone = true);

    // Splash -> Login -> Home (no-op in architecture test)

    // Connect Machine
    final device = DeviceInfo(id: 'mock-1', name: 'MockDevice', rssi: -42);
    await connectionManager.connect(device);

    // wait a short moment for connection transitions to be emitted
    await Future<void>.delayed(Duration(milliseconds: 50));
    expect(connStates.isNotEmpty, true, reason: 'Connection manager should emit at least connecting; saw: $connStates');

    // Camera Studio: initialize and start preview
    await cameraController.initialize();
    await cameraController.startPreview();

    // ensure preview frames flow by awaiting the first frame via existing subscription
    final frame = await frameCompleter.future.timeout(Duration(seconds: 4));
    expect((frame as dynamic).bytes?.isNotEmpty ?? false, true);

    // Select preset and capture photo
    final presetId = PresetManager().getPreset('white-background').id;
    final session = CaptureSession(id: 'validation', mode: CaptureMode.singlePhoto, presetId: presetId);

    // start capture session and wait for completion or failure event
    final evtFuture = orchestrator.eventStream.firstWhere((e) => e.id == 'completed' || e.id == 'failed');
    await orchestrator.startSession(session);
    final resultEvent = await evtFuture.timeout(Duration(seconds: 12));
    expect(['completed', 'failed'].contains(resultEvent.id), true);
    // verify orchestrator emitted core step events
    expect(events.contains('initialize'), true);
    expect(events.contains('capture'), true);
    expect(events.contains('complete') || events.contains('process'), true);

    // Processing -> Gallery -> Export (logical boundaries covered by orchestrator+controllers)

    // Verify no uncaught exceptions (test infrastructure will catch them)

    // Verify providers disposed correctly: call dispose and ensure streams close
    await Future<void>.delayed(Duration(milliseconds: 100));

    orchestrator.dispose();
    await cameraController.dispose();
    connectionManager.dispose();
    await engine.dispose();

    // wait briefly for done callbacks
    await Future<void>.delayed(Duration(milliseconds: 100));

    expect(connectionDone, true, reason: 'Connection manager stream should be closed after dispose');
    expect(previewDone, true, reason: 'Camera preview stream should be closed after engine dispose');
    expect(eventsDone, true, reason: 'Orchestrator events stream should be closed after dispose');

    // ensure no lingering subscriptions by cancelling ours
    await connSub.cancel();
    await prevSub.cancel();
    await evtSub.cancel();
  }, timeout: Timeout(Duration(seconds: 30)));
}
