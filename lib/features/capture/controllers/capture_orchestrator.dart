import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:aig/features/camera/controllers/camera_controller.dart';
import 'package:aig/features/camera/controllers/capture_controller.dart';
import 'package:aig/features/capture/models/capture_session.dart';
import 'package:aig/features/capture/models/capture_sequence.dart';
import 'package:aig/features/capture/models/capture_step.dart';
import 'package:aig/features/capture/models/capture_workflow_state.dart';
import 'package:aig/features/capture/models/capture_workflow_stage.dart';
import 'package:aig/features/capture/models/capture_progress.dart';
import 'package:aig/features/capture/models/capture_event.dart';
import 'package:aig/features/capture/models/capture_result_aggregator.dart';
import 'package:aig/features/capture/models/capture_cancellation_token.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart'
    hide RotationConfig, LightingConfig;
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/preset_studio/services/preset_workflow_planner.dart';
import 'package:aig/features/camera/services/media_store_publisher.dart';
import 'package:aig/features/esp32/controllers/machine_controller.dart';
import 'package:aig/features/esp32/models/rotation_config.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';
import 'package:aig/features/esp32/services/device_connection_manager.dart';
import 'package:aig/features/esp32/services/diamondcam_service.dart';
import 'package:aig/features/processing/services/jewelry_video_processor.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_metadata.dart';
import 'package:aig/features/gallery/models/media_type.dart';

/// Coordinates the full capture workflow as a finite state machine.
class CaptureOrchestrator {
  final MachineController _machineController;
  final DeviceConnectionManager _connectionManager;
  final CameraController _cameraController;
  final CaptureController _captureController;
  final StreamController<CaptureWorkflowState> _stateController =
      StreamController.broadcast();
  final StreamController<CaptureEvent> _eventController =
      StreamController.broadcast();
  final PresetManager _presetManager = const PresetManager();
  CaptureWorkflowState _state = CaptureWorkflowState.initial(
    CaptureMode.singlePhoto,
  );
  CaptureCancellationToken? _cancellationToken;
  CaptureResultAggregator _aggregator = const CaptureResultAggregator();
  String? _latestCapturedFilePath;
  String? _latestMediaStoreUri;
  int? _latestFileSizeBytes;
  bool _sessionInFlight = false;
  bool _videoRecording = false;
  CaptureSession? _activeVideoSession;
  CaptureSession? _activeSession;
  bool _disposed = false;
  bool _startedRotationForVideo = false;
  Timer? _timedStopTimer;
  String? _latestProcessedPath;
  String? _latestProcessedUri;
  bool _machineVerifiedCached = false;
  final Future<void> Function(MediaItem item)? _onMediaPersisted;
  final DiamondCamService? _diamondCam;
  final JewelryVideoProcessor? _videoProcessor;
  final CameraPreset Function(String id)? _resolvePreset;
  final PresetWorkflowPlanner _planner = const PresetWorkflowPlanner();

  bool get _machineVerified => _machineVerifiedCached;

  Future<void> _refreshMachineVerified() async {
    final diamond = _diamondCam;
    if (diamond != null) {
      try {
        final health = await diamond.getHealth();
        _machineVerifiedCached = health.ok;
        return;
      } catch (_) {
        _machineVerifiedCached = false;
        return;
      }
    }
    _machineVerifiedCached = _connectionManager.currentState.status ==
        ConnectionStatus.connected;
  }

  CaptureOrchestrator({
    required MachineController machineController,
    required DeviceConnectionManager connectionManager,
    required CameraController cameraController,
    required CaptureController captureController,
    Future<void> Function(MediaItem item)? onMediaPersisted,
    DiamondCamService? diamondCam,
    JewelryVideoProcessor? videoProcessor,
    CameraPreset Function(String id)? resolvePreset,
  }) : _machineController = machineController,
       _connectionManager = connectionManager,
       _cameraController = cameraController,
       _captureController = captureController,
       _onMediaPersisted = onMediaPersisted,
       _diamondCam = diamondCam,
       _videoProcessor = videoProcessor,
       _resolvePreset = resolvePreset {
    _stateController.add(_state);
  }

  Stream<CaptureWorkflowState> get stateStream => _stateController.stream;
  Stream<CaptureEvent> get eventStream => _eventController.stream;
  String? get latestCapturedFilePath => _latestCapturedFilePath;
  String? get latestMediaStoreUri => _latestMediaStoreUri;
  int? get latestFileSizeBytes => _latestFileSizeBytes;
  String? get latestProcessedPath => _latestProcessedPath;
  String? get latestProcessedUri => _latestProcessedUri;
  bool get isRecordingVideo => _videoRecording;

  CameraPreset _presetFor(String id) {
    var preset = _resolvePreset?.call(id) ?? _presetManager.getPreset(id);
    final session = _activeSession ?? _activeVideoSession;
    if (session != null && session.presetId == id) {
      preset = preset.copyWith(
        processingLook: session.lookOverride ?? preset.processingLook,
        filterStrength: session.filterStrength ?? preset.filterStrength,
        lightOn: session.lightOnOverride ?? preset.lightOn,
        lightIntensity: session.lightIntensityOverride ?? preset.lightIntensity,
      );
    }
    return preset;
  }

  Future<void> startSession(CaptureSession session) async {
    if (_disposed) {
      throw StateError(
        'Capture workflow is disposed and cannot start a new session.',
      );
    }
    if (_sessionInFlight || _videoRecording) {
      await _emitEvent(
        'duplicate-session',
        'Capture session already in progress',
      );
      return;
    }

    _sessionInFlight = true;
    _activeSession = session;
    _latestCapturedFilePath = null;
    _latestProcessedPath = null;
    _latestProcessedUri = null;
    await _refreshMachineVerified();
    _transitionTo(
      CaptureWorkflowState.initial(session.mode).copyWith(
        stage: CaptureWorkflowStage.preparing,
        isRunning: true,
        currentStep: 'Preparing session',
        message: 'Initializing capture workflow',
        progress: const CaptureProgress(totalSteps: 0, completedSteps: 0),
      ),
    );
    _cancellationToken = CaptureCancellationToken();
    _aggregator = const CaptureResultAggregator();

    try {
      if (session.mode.isVideo) {
        await _beginVideoRecording(session);
        return;
      }
      final sequence = _buildSequence(session);
      await _runSequence(sequence, session);
    } catch (error) {
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.failed,
          hasFailed: true,
          isRunning: false,
          currentStep: 'Failed',
          message: 'Capture workflow failed: $error',
        ),
      );
      await _emitEvent('failed', 'Capture workflow failed: $error');
    } finally {
      _sessionInFlight = false;
    }
  }

  Future<void> cancelSession() async {
    _timedStopTimer?.cancel();
    _timedStopTimer = null;
    _cancellationToken?.cancel();
    if (_videoRecording) {
      try {
        await _captureController.stopVideo();
      } catch (_) {}
    }
    await _stopVerifiedMachineForVideo();
    _videoRecording = false;
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.cancelled,
        isCancelled: true,
        isRunning: false,
        currentStep: 'cancelled',
        message: 'Session cancelled',
      ),
    );
    await _emitEvent('cancelled', 'Capture session cancelled');
  }

  Future<void> reset() async {
    _cancellationToken = null;
    _state = CaptureWorkflowState.initial(_state.mode);
    _stateController.add(_state);
    await _emitEvent('reset', 'Capture workflow reset');
  }

  CaptureSequence _buildSequence(CaptureSession session) {
    final steps = <CaptureStep>[..._buildCoreSteps(session)];
    return CaptureSequence(mode: session.mode, steps: steps);
  }

  List<CaptureStep> _buildCoreSteps(CaptureSession session) {
    return [
      CaptureStep(
        id: 'initialize',
        name: 'Initialize',
        timeout: const Duration(seconds: 10),
        action: () async => _initialize(session),
      ),
      CaptureStep(
        id: 'validate_connection',
        name: 'Validate Machine Connection',
        timeout: const Duration(seconds: 10),
        action: () async => _validateMachine(),
      ),
      CaptureStep(
        id: 'validate_camera',
        name: 'Validate Camera Ready',
        timeout: const Duration(seconds: 10),
        action: () async => _validateCamera(),
      ),
      CaptureStep(
        id: 'configure_machine',
        name: 'Configure Machine',
        timeout: const Duration(seconds: 15),
        action: () async => _configureMachine(session),
      ),
      CaptureStep(
        id: 'configure_camera',
        name: 'Configure Camera',
        timeout: const Duration(seconds: 15),
        action: () async => _configureCamera(session),
      ),
      CaptureStep(
        id: 'stabilize',
        name: 'Wait For Stabilization',
        timeout: const Duration(seconds: 5),
        action: () async => _stabilize(),
      ),
      CaptureStep(
        id: 'capture',
        name: 'Capture',
        timeout: const Duration(seconds: 30),
        action: () async => _capture(session),
      ),
      CaptureStep(
        id: 'process',
        name: 'Processing',
        timeout: const Duration(seconds: 20),
        action: () async => _process(),
      ),
      CaptureStep(
        id: 'complete',
        name: 'Complete',
        timeout: const Duration(seconds: 5),
        action: () async => _complete(),
      ),
    ];
  }

  Future<CaptureStepResult> _runStep(CaptureStep step) async {
    if (_cancellationToken?.isCancelled == true) {
      return CaptureStepResult.failure(
        'Cancelled before step start',
        isCritical: false,
      );
    }

    _transitionTo(
      _state.copyWith(
        stage: _stageForStep(step.id),
        currentStep: step.name,
        isRunning: true,
        message: 'Running ${step.name}',
      ),
    );
    await _emitEvent(step.id, 'Starting ${step.name}');

    final completer = Completer<CaptureStepResult>();
    late final Timer? timeoutTimer;
    var timedOut = false;

    if (step.timeout != null) {
      timeoutTimer = Timer(step.timeout!, () {
        timedOut = true;
        if (!completer.isCompleted) {
          completer.complete(
            CaptureStepResult.failure(
              'Step timed out',
              shouldRetry: true,
              isCritical: true,
            ),
          );
        }
      });
    } else {
      timeoutTimer = null;
    }

    Future<void>.microtask(() async {
      try {
        final result = await step.action();
        if (!timedOut && !completer.isCompleted) {
          completer.complete(result);
        }
      } catch (error) {
        if (!timedOut && !completer.isCompleted) {
          completer.complete(
            CaptureStepResult.failure(
              'Unhandled step error: $error',
              shouldRetry: true,
            ),
          );
        }
      }
    });

    final result = await completer.future;
    timeoutTimer?.cancel();
    if (timedOut) {
      _cancellationToken?.cancel();
    }
    return result;
  }

  Future<void> _runSequence(
    CaptureSequence sequence,
    CaptureSession session,
  ) async {
    final total = sequence.totalSteps;
    var completed = 0;

    for (var index = 0; index < total; index++) {
      if (_cancellationToken?.isCancelled == true) {
        _transitionTo(
          _state.copyWith(
            stage: CaptureWorkflowStage.cancelled,
            isCancelled: true,
            isRunning: false,
            message: 'Session cancelled',
          ),
        );
        return;
      }

      final step = sequence.steps[index];
      final result = await _runStep(step);
      _aggregator = _aggregator.add(result);
      completed += 1;
      _updateProgress(total, completed, step.id);

      if (!result.success) {
        if (result.shouldRetry && !_cancellationToken!.isCancelled) {
          await Future<void>.delayed(const Duration(seconds: 1));
          final retryResult = await _runStep(step);
          _aggregator = _aggregator.add(retryResult);
          if (!retryResult.success && retryResult.isCritical) {
            _transitionTo(
              _state.copyWith(
                hasFailed: true,
                isRunning: false,
                message: 'Workflow failed at ${step.name}',
              ),
            );
            await _emitEvent('failed', 'Step ${step.name} failed after retry');
            return;
          }
        } else {
          _transitionTo(
            _state.copyWith(
              stage: CaptureWorkflowStage.failed,
              hasFailed: true,
              isRunning: false,
              message: 'Workflow failed at ${step.name}',
            ),
          );
          await _emitEvent('failed', 'Step ${step.name} failed');
          return;
        }
      }
    }

    if (_state.isCancelled) {
      return;
    }

    if (!_state.hasFailed) {
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.completed,
          isRunning: false,
          message: 'Workflow completed',
          currentStep: 'Completed',
        ),
      );
      await _emitEvent('completed', 'Capture session completed');
    }
  }

  Future<CaptureStepResult> _initialize(CaptureSession session) async {
    try {
      if (!_cameraController.isPreviewing) {
        await _cameraController.initialize();
        await _cameraController.startPreview();
      }
      return CaptureStepResult.success('Initialized session ${session.id}');
    } catch (error) {
      return CaptureStepResult.failure(
        'Failed to initialize camera: $error',
        shouldRetry: true,
        isCritical: true,
      );
    }
  }

  Future<CaptureStepResult> _validateMachine() async {
    await _refreshMachineVerified();
    if (_machineVerified) {
      return CaptureStepResult.success('Machine connected and verified');
    }
    return CaptureStepResult.success(
      'Camera-only capture; machine is not verified and will not block recording',
    );
  }

  Future<CaptureStepResult> _validateCamera() async {
    try {
      await _cameraController.startPreview();
      return CaptureStepResult.success('Camera preview started');
    } catch (error) {
      return CaptureStepResult.failure(
        'Camera preview unavailable: $error',
        shouldRetry: true,
        isCritical: true,
      );
    }
  }

  Future<CaptureStepResult> _configureMachine(CaptureSession session) async {
    if (session.presetId == null || !_machineVerified) {
      return CaptureStepResult.success(
        'Camera-only: machine configure skipped',
      );
    }
    final preset = _presetFor(session.presetId!);
    try {
      await _applyPresetLighting(preset);
      if (preset.usesContinuousRotation && session.mode.isVideo) {
        final started = await _startPresetRotation(preset);
        if (!started) {
          return CaptureStepResult.failure(
            'Rotation command was not accepted',
            shouldRetry: false,
            isCritical: true,
          );
        }
      }
      return CaptureStepResult.success('Machine configured');
    } catch (error) {
      await _stopVerifiedMachineForVideo();
      return CaptureStepResult.failure(
        'Machine configure failed: $error',
        shouldRetry: false,
        isCritical: true,
      );
    }
  }

  Future<CaptureStepResult> _configureCamera(CaptureSession session) async {
    if (session.presetId != null) {
      final preset = _presetFor(session.presetId!);
      await _cameraController.zoom.smoothZoomTo(
        1.0,
        const Duration(milliseconds: 300),
      );
      await _cameraController.exposure.setExposureCompensation(0.0);
      await _cameraController.focus.autoFocus();
      _state = _state.copyWith(
        message: 'Applied ${preset.name} camera settings',
      );
      _stateController.add(_state);
      return CaptureStepResult.success('Camera configured with ${preset.name}');
    }
    return CaptureStepResult.success('Camera configured');
  }

  Future<CaptureStepResult> _stabilize() async {
    return CaptureStepResult.success('Camera is ready to capture');
  }

  Future<CaptureStepResult> _capture(CaptureSession session) async {
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.capturingPhoto,
        currentStep: 'Capturing photo',
        message: 'Capturing photo',
      ),
    );
    final result = await _captureController.capturePhoto(
      session.captureSettings,
    );
    final jpeg = result.jpeg;
    if (jpeg == null || jpeg.isEmpty) {
      return CaptureStepResult.failure(
        'Photo capture did not produce image bytes',
        isCritical: true,
      );
    }
    final directory = await _captureDirectory();
    await directory.create(recursive: true);
    final path =
        '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(jpeg, flush: true);
    final size = await File(path).length();
    if (size <= 0) {
      return CaptureStepResult.failure(
        'Photo capture produced an empty file',
        isCritical: true,
      );
    }
    _latestCapturedFilePath = path;
    _latestFileSizeBytes = size;
    final published = await MediaStorePublisher.publishPhoto(path);
    if (Platform.isAndroid && (published == null || published.isEmpty)) {
      return CaptureStepResult.failure(
        'Photo could not be saved to the phone gallery',
        isCritical: true,
      );
    }
    _latestMediaStoreUri = published ?? File(path).uri.toString();
    return CaptureStepResult.success('Photo captured');
  }

  Future<CaptureStepResult> _process() async {
    return CaptureStepResult.success(
      'Processing skipped; original capture is saved',
    );
  }

  Future<Directory> _captureDirectory() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return Directory('${documentsDirectory.path}/captures');
    } catch (_) {
      return Directory.systemTemp.createTempSync('aig_captures_test_');
    }
  }

  Future<CaptureStepResult> _complete() async {
    final persisted = await _persistLatestCapture(
      presetId: _activeSession?.presetId,
    );
    if (!persisted) {
      return CaptureStepResult.failure(
        'Capture completed but was not added to AIG Gallery',
      );
    }
    return CaptureStepResult.success('Workflow complete');
  }

  Future<void> _beginVideoRecording(CaptureSession session) async {
    _activeVideoSession = session;
    _timedStopTimer?.cancel();
    final init = await _initialize(session);
    if (!init.success) {
      throw StateError(init.message);
    }
    final camera = await _validateCamera();
    if (!camera.success) {
      throw StateError(camera.message);
    }
    await _refreshMachineVerified();
    CameraPreset? preset;
    if (session.presetId != null) {
      preset = _presetFor(session.presetId!);
      final plan = _planner.plan(
        preset: preset,
        cameraReady: true,
        machineVerified: _machineVerified,
        isVideo: true,
      );
      if (!plan.canExecute) {
        throw StateError(plan.blockedReason ?? 'Preset cannot run');
      }
    }
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.configuringMachine,
        isRunning: true,
        currentStep: 'Configuring machine',
        message: 'Applying lighting and rotation',
      ),
    );
    await _startVerifiedMachineForVideo(session);
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.startingVideo,
        isRunning: true,
        currentStep: 'Starting recording',
        message: 'Starting recording',
      ),
    );
    await _captureController.startVideo(session.captureSettings);
    _videoRecording = true;
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.recordingVideo,
        isRunning: true,
        currentStep: 'Recording',
        message: 'Recording',
      ),
    );
    await _emitEvent('recording', 'Video recording started');
    final durationSeconds = preset?.captureDurationSeconds ?? 0;
    if (durationSeconds > 0) {
      _timedStopTimer = Timer(Duration(seconds: durationSeconds), () {
        unawaited(stopActiveVideo());
      });
    }
  }

  Future<void> _startVerifiedMachineForVideo(CaptureSession session) async {
    _startedRotationForVideo = false;
    if (!_machineVerified) {
      return;
    }
    try {
      CameraPreset? preset;
      if (session.presetId != null) {
        preset = _presetFor(session.presetId!);
      }
      if (preset != null) {
        await _applyPresetLighting(preset);
        if (preset.usesContinuousRotation ||
            preset.rotationMode != MachineRotationMode.none) {
          _startedRotationForVideo = await _startPresetRotation(preset);
        }
      } else {
        await _configureMachine(session);
      }
    } catch (error) {
      await _stopVerifiedMachineForVideo();
      _startedRotationForVideo = false;
      await _emitEvent(
        'machine-sync-failed',
        'Recording continued without machine motion: $error',
      );
    }
  }

  Future<void> _applyPresetLighting(CameraPreset preset) async {
    final diamondCam = _diamondCam;
    if (diamondCam != null) {
      final result = await diamondCam.setLight(
        state: preset.lightOn,
        intensity: preset.lightIntensity,
      );
      if (!result.ok) {
        throw StateError(result.message);
      }
      return;
    }
    await _machineController.lighting.setMasterBrightness(
      preset.lightingConfig.brightness,
    );
  }

  Future<bool> _startPresetRotation(CameraPreset preset) async {
    final diamondCam = _diamondCam;
    if (diamondCam != null) {
      if (preset.rotationMode == MachineRotationMode.angle &&
          preset.machineAngle != null) {
        final result = await diamondCam.rotate(
          angle: preset.machineAngle!,
          speed: preset.machineSpeed,
        );
        return result.ok;
      }
      final result = await diamondCam.continuous(
        direction: preset.rotationDirection == DiamondCamProtocol.directionCcw
            ? DiamondCamProtocol.directionCcw
            : DiamondCamProtocol.directionCw,
        speed: preset.machineSpeed,
      );
      return result.ok;
    }
    await _machineController.rotation.start(
      RotationConfig(
        speed: preset.machineSpeed / 100.0,
        clockwise: preset.rotationDirection != 'ccw',
        continuous: true,
      ),
    );
    return true;
  }

  Future<void> _stopVerifiedMachineForVideo() async {
    _timedStopTimer?.cancel();
    _timedStopTimer = null;
    if (!_startedRotationForVideo && _diamondCam == null) {
      return;
    }
    _startedRotationForVideo = false;
    try {
      final diamondCam = _diamondCam;
      if (diamondCam != null) {
        await diamondCam.stop();
      } else {
        await _machineController.rotation.stop();
      }
    } catch (_) {}
  }

  Future<void> stopActiveVideo() async {
    if (!_videoRecording) {
      throw StateError('No video recording is active');
    }
    if (_sessionInFlight) {
      return;
    }
    _sessionInFlight = true;
    _timedStopTimer?.cancel();
    _timedStopTimer = null;
    try {
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.stoppingVideo,
          isRunning: true,
          currentStep: 'Stopping recording',
          message: 'Stopping recording',
        ),
      );
      final result = await _captureController.stopVideo();
      await _stopVerifiedMachineForVideo();
      final videoPath = result.videoPath;
      if (videoPath == null ||
          videoPath.isEmpty ||
          !File(videoPath).existsSync()) {
        throw StateError('Video recording completed without a valid file');
      }
      final size = await File(videoPath).length();
      if (size < 8192 ||
          !await MediaStorePublisher.validateCaptureFile(videoPath, 'video')) {
        throw StateError('Video recording is empty or invalid');
      }
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.savingMedia,
          currentStep: 'Saving video',
          message: 'Saving original recording',
        ),
      );
      final publishedPath = await MediaStorePublisher.publishVideo(videoPath);
      if (Platform.isAndroid &&
          (publishedPath == null || publishedPath.isEmpty)) {
        throw StateError('Video could not be saved to the phone gallery');
      }
      _latestCapturedFilePath = videoPath;
      _latestFileSizeBytes = size;
      _latestMediaStoreUri = publishedPath ?? File(videoPath).uri.toString();
      final persisted = await _persistLatestCapture(
        presetId: _activeVideoSession?.presetId,
        notes: 'Original recording',
      );
      if (!persisted) {
        throw StateError(
          'Video saved to MediaStore but was not added to AIG Gallery',
        );
      }
      await _processLatestVideo();
      _videoRecording = false;
      _activeVideoSession = null;
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.completed,
          isRunning: false,
          hasFailed: false,
          currentStep: 'Completed',
          message: _latestProcessedPath != null
              ? 'Processed video ready'
              : 'Video saved',
        ),
      );
      await _emitEvent('completed', 'Video capture completed');
    } catch (error) {
      await _stopVerifiedMachineForVideo();
      _videoRecording = false;
      _activeVideoSession = null;
      _transitionTo(
        _state.copyWith(
          stage: CaptureWorkflowStage.failed,
          hasFailed: true,
          isRunning: false,
          currentStep: 'Failed',
          message: error.toString(),
        ),
      );
      await _emitEvent('failed', error.toString());
      rethrow;
    } finally {
      _sessionInFlight = false;
    }
  }

  Future<void> _processLatestVideo() async {
    final processor = _videoProcessor;
    final source = _latestCapturedFilePath;
    final session = _activeVideoSession;
    if (processor == null || source == null || session?.presetId == null) {
      return;
    }
    final preset = _presetFor(session!.presetId!);
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.processing,
        currentStep: 'Processing',
        message: 'Grading jewelry video',
        isRunning: true,
      ),
    );
    final processed = await processor.process(
      sourcePath: source,
      preset: preset,
    );
    await _emitEvent(
      processed.success ? 'processed' : 'process-failed',
      '${processed.message} (${processed.elapsedMs}ms)',
    );
    if (!processed.success ||
        processed.outputPath == null ||
        processed.usedOriginal) {
      _transitionTo(
        _state.copyWith(
          message: processed.success
              ? 'Original recording kept. ${processed.message}'
              : 'Processing failed. Original recording kept. ${processed.message}',
        ),
      );
      return;
    }
    _transitionTo(
      _state.copyWith(
        stage: CaptureWorkflowStage.verifyingOutput,
        currentStep: 'Verifying output',
        message: processed.message,
        isRunning: true,
      ),
    );
    _latestProcessedPath = processed.outputPath;
    final published = await MediaStorePublisher.publishVideo(
      processed.outputPath!,
    );
    _latestProcessedUri =
        published ?? File(processed.outputPath!).uri.toString();
    await _persistProcessedCapture(
      path: processed.outputPath!,
      uri: _latestProcessedUri!,
      presetId: preset.id,
    );
  }

  Future<bool> _persistLatestCapture({
    String? presetId,
    String notes = 'Verified capture',
  }) async {
    final path = _latestCapturedFilePath;
    final uri = _latestMediaStoreUri;
    if (path == null || path.isEmpty || uri == null || uri.isEmpty) {
      return false;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return false;
    }
    final size = _latestFileSizeBytes ?? await file.length();
    if (size <= 0) {
      return false;
    }
    final sink = _onMediaPersisted;
    if (sink == null) {
      return true;
    }
    final isVideo = path.toLowerCase().endsWith('.mp4');
    final item = MediaItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_$size',
      title: isVideo
          ? 'Video ${DateTime.now().toIso8601String()}'
          : 'Photo ${DateTime.now().toIso8601String()}',
      mediaType: isVideo ? MediaType.video : MediaType.photo,
      storagePath: uri,
      createdAt: DateTime.now(),
      thumbnailPath: path,
      metadata: MediaMetadata(
        captureDate: DateTime.now(),
        captureSessionId: _activeSession?.id ?? _activeVideoSession?.id,
        presetUsed:
            presetId ??
            _activeSession?.presetId ??
            _activeVideoSession?.presetId,
        fileSizeBytes: size,
        notes: notes,
      ),
    );
    await sink(item);
    return true;
  }

  Future<void> _persistProcessedCapture({
    required String path,
    required String uri,
    required String presetId,
  }) async {
    final sink = _onMediaPersisted;
    if (sink == null) {
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }
    final size = await file.length();
    await sink(
      MediaItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_processed_$size',
        title: 'Processed ${DateTime.now().toIso8601String()}',
        mediaType: MediaType.video,
        storagePath: uri,
        createdAt: DateTime.now(),
        thumbnailPath: path,
        metadata: MediaMetadata(
          captureDate: DateTime.now(),
          captureSessionId: _activeVideoSession?.id,
          presetUsed: presetId,
          fileSizeBytes: size,
          notes: 'Processed jewelry video',
        ),
      ),
    );
  }

  void _updateProgress(int total, int completed, String currentStep) {
    final progress = CaptureProgress(
      totalSteps: total,
      completedSteps: completed,
      currentStepId: currentStep,
    );
    _transitionTo(
      _state.copyWith(
        progress: progress,
        currentStep: currentStep,
        message: 'Step $currentStep complete',
      ),
    );
  }

  CaptureWorkflowStage _stageForStep(String stepId) {
    switch (stepId) {
      case 'initialize':
        return CaptureWorkflowStage.preparing;
      case 'validate_connection':
      case 'validate_camera':
        return CaptureWorkflowStage.validating;
      case 'configure_machine':
        return CaptureWorkflowStage.configuringMachine;
      case 'configure_camera':
        return CaptureWorkflowStage.configuringCamera;
      case 'stabilize':
        return CaptureWorkflowStage.waitingForStabilization;
      case 'capture':
        return CaptureWorkflowStage.capturingPhoto;
      case 'process':
        return CaptureWorkflowStage.processing;
      case 'complete':
        return CaptureWorkflowStage.savingMedia;
      default:
        return CaptureWorkflowStage.preparing;
    }
  }

  void _transitionTo(CaptureWorkflowState next) {
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> _emitEvent(String type, String message) async {
    if (_eventController.isClosed) {
      return;
    }
    _eventController.add(
      CaptureEvent(id: type, description: message, timestamp: DateTime.now()),
    );
  }

  void dispose() {
    _disposed = true;
    _timedStopTimer?.cancel();
    if (!_stateController.isClosed) {
      _stateController.close();
    }
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}
