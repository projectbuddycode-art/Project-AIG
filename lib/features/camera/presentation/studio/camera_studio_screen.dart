import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/models/camera_state.dart';
import 'package:aig/features/camera/providers/camera_providers.dart';
import 'package:aig/features/capture/models/capture_session.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/providers/capture_providers.dart';
import 'package:aig/features/esp32/providers/diamondcam_state_provider.dart';
import 'package:aig/features/esp32/models/device_connection_state.dart';
import 'package:aig/features/capture/models/capture_workflow_stage.dart';
import 'package:aig/features/capture/models/capture_workflow_state.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart'
    as preset_model;
import 'package:aig/features/camera/preset_studio/providers/preset_providers.dart';
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/presentation/studio/camera_preview_widget.dart';
import 'package:aig/features/camera/presentation/studio/studio_rotation_panel.dart';
import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/presentation/studio/studio_lighting_panel.dart';
import 'package:aig/features/camera/presentation/studio/studio_filter_panel.dart';
import 'package:aig/features/camera/presentation/studio/studio_preset_selector.dart';
import 'package:aig/features/camera/presentation/studio/studio_capture_button.dart';
import 'package:aig/features/camera/presentation/studio/studio_panel_card.dart';

class CameraStudioScreen extends ConsumerStatefulWidget {
  const CameraStudioScreen({super.key, this.initialPresetId});

  final String? initialPresetId;

  @override
  ConsumerState<CameraStudioScreen> createState() => _CameraStudioScreenState();
}

enum _StudioCaptureMode { photo, video }

class _CameraStudioScreenState extends ConsumerState<CameraStudioScreen>
    with SingleTickerProviderStateMixin {
  final _presetManager = const PresetManager();
  String _selectedPresetId = 'diamond-luxury-360';
  bool _sheetExpanded = false;
  double _sheetHeight = 104.0;
  static const double _sheetMinHeight = 104.0;
  static const double _sheetMaxHeight = 420.0;
  double _localZoom = 1.0;
  int _lightingIntensity = 80;
  bool _lightingEnabled = true;
  int _filterStrength = 70;
  preset_model.JewelryProcessingLook _look =
      preset_model.JewelryProcessingLook.luxuryDark;
  double _rotationSpeed = 30;
  double _rotationDegrees = 45;
  bool _machineBusy = false;
  Timer? _lightingDebounce;
  late final TabController _tabController;
  bool _captureInFlight = false;
  bool _captureFeedbackVisible = false;
  bool _captureFlashVisible = false;
  String _captureFeedbackLabel = 'Ready';
  _StudioCaptureMode _captureMode = _StudioCaptureMode.photo;
  bool _showAdvancedControls = false;
  Timer? _captureFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedPresetId = widget.initialPresetId ?? _selectedPresetId;
    final initialPreset = _presetManager.getPreset(_selectedPresetId);
    _captureMode = initialPreset.isVideoPreset
        ? _StudioCaptureMode.video
        : _StudioCaptureMode.photo;
    _lightingIntensity = initialPreset.lightIntensity;
    _lightingEnabled = initialPreset.lightOn;
    _look = initialPreset.processingLook;
    _filterStrength = initialPreset.filterStrength;
    _rotationSpeed = initialPreset.machineSpeed.toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publishLook();
    });
  }

  @override
  void dispose() {
    _captureFeedbackTimer?.cancel();
    _lightingDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onTapFocus() async {
    final camera = ref.read(cameraControllerProvider);
    await camera.focus.autoFocus();
    ref.read(cameraStateNotifierProvider.notifier).updateFocus(1.0);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final newZoom = (_localZoom * details.scale).clamp(1.0, 8.0);
    setState(() => _localZoom = newZoom);
    ref.read(cameraControllerProvider).zoom.setZoom(newZoom);
    ref.read(cameraStateNotifierProvider.notifier).updateZoom(newZoom);
  }

  void _setCaptureFeedback(
    String label, {
    bool show = true,
    bool flash = false,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    if (!mounted) return;
    _captureFeedbackTimer?.cancel();
    setState(() {
      _captureFeedbackVisible = show;
      _captureFeedbackLabel = label;
      _captureFlashVisible = show && flash;
    });
    if (show) {
      _captureFeedbackTimer = Timer(duration, () {
        if (!mounted) return;
        setState(() {
          _captureFeedbackVisible = false;
          _captureFlashVisible = false;
        });
      });
    }
  }

  Future<void> _previewLatestExport() async {
    final orchestrator = ref.read(captureOrchestratorProvider);
    final uri =
        orchestrator.latestProcessedUri ?? orchestrator.latestMediaStoreUri;
    if (uri == null || uri.isEmpty) {
      return;
    }
    try {
      await const MethodChannel('aig.camera/methods').invokeMethod<void>(
        'openMedia',
        <String, dynamic>{'uri': uri, 'mimeType': 'video/mp4'},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview could not open: $error')));
    }
  }

  Future<void> _startCapture() async {
    final orchestrator = ref.read(captureOrchestratorProvider);
    final workflowState = ref.read(captureWorkflowStateProvider).value;
    if (_captureInFlight) {
      return;
    }
    if (orchestrator.isRecordingVideo) {
      setState(() => _captureInFlight = true);
      _setCaptureFeedback('Stopping recording…', show: true, flash: false);
      try {
        await orchestrator.stopActiveVideo();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video did not save. ${error.toString()}')),
        );
        _setCaptureFeedback('Recording failed', show: true, flash: false);
      } finally {
        if (mounted) {
          setState(() => _captureInFlight = false);
        }
      }
      return;
    }
    if (workflowState?.isRunning ?? false) {
      return;
    }

    setState(() => _captureInFlight = true);
    _setCaptureFeedback(
      _captureMode == _StudioCaptureMode.video
          ? 'Starting recording…'
          : 'Capturing photo…',
      show: true,
      flash: _captureMode == _StudioCaptureMode.photo,
    );
    HapticFeedback.lightImpact();
    final session = CaptureSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mode: _captureMode == _StudioCaptureMode.video
          ? CaptureMode.video360
          : CaptureMode.singlePhoto,
      presetId: _selectedPresetId,
      lookOverride: _look,
      filterStrength: _filterStrength,
      lightOnOverride: _lightingEnabled,
      lightIntensityOverride: _lightingIntensity,
    );
    try {
      await orchestrator.startSession(session);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Capture did not complete. ${error.toString()}'),
        ),
      );
      _setCaptureFeedback('Capture failed', show: true, flash: false);
    } finally {
      if (mounted) {
        setState(() => _captureInFlight = false);
      }
    }
  }

  Future<void> _setExposure(double value) async {
    final previous = ref.read(cameraStateNotifierProvider).exposure;
    ref.read(cameraStateNotifierProvider.notifier).updateExposure(value);
    try {
      await ref
          .read(cameraControllerProvider)
          .exposure
          .setExposureCompensation(value);
    } catch (error) {
      if (!mounted) return;
      ref.read(cameraStateNotifierProvider.notifier).updateExposure(previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exposure settings could not be updated: ${error.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _cycleFlashMode(String currentMode) async {
    const modes = <String>['auto', 'off', 'on', 'torch'];
    final currentIndex = modes.indexOf(currentMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    final previous = ref.read(cameraStateNotifierProvider).flashMode;
    ref.read(cameraStateNotifierProvider.notifier).updateFlashMode(nextMode);

    try {
      await ref.read(cameraControllerProvider).flash.setFlashMode(nextMode);
    } catch (error) {
      if (!mounted) return;
      ref.read(cameraStateNotifierProvider.notifier).updateFlashMode(previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Flash settings could not be updated: ${error.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _setMasterLight(bool on) async {
    final previous = _lightingEnabled;
    setState(() => _lightingEnabled = on);
    final diamond = ref.read(diamondCamStateProvider);
    if (diamond.phase != DiamondCamPhase.verified) {
      setState(() => _lightingEnabled = previous);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lighting is not sent while the machine is disconnected.',
          ),
        ),
      );
      return;
    }
    await _runMachineCommand(() async {
      final intensity = on
          ? (_lightingIntensity <= 0 ? 80 : _lightingIntensity)
          : 0;
      return ref
          .read(diamondCamStateProvider.notifier)
          .setLight(on: on, intensity: intensity);
    }, 'Lighting could not be updated');
    if (!mounted) return;
    final after = ref.read(diamondCamStateProvider);
    if (after.phase == DiamondCamPhase.error ||
        after.phase == DiamondCamPhase.disconnected) {
      setState(() => _lightingEnabled = previous);
    }
  }

  Future<void> _runMachineCommand(
    Future<String> Function() action,
    String failureLabel,
  ) async {
    if (_machineBusy) {
      return;
    }
    setState(() => _machineBusy = true);
    try {
      final message = await action();
      if (!mounted) return;
      final diamond = ref.read(diamondCamStateProvider);
      final failed =
          diamond.phase == DiamondCamPhase.error ||
          diamond.phase == DiamondCamPhase.disconnected;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failed ? '$failureLabel: $message' : message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$failureLabel: ${error.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _machineBusy = false);
      } else {
        _machineBusy = false;
      }
    }
  }

  void _publishLook() {
    ref.read(jewelryLookPreviewProvider.notifier).state = JewelryLookPreview(
      look: _look,
      strength: _filterStrength,
    );
  }

  void _queueLightingUpdate() {
    _lightingDebounce?.cancel();
    _lightingDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(
        _runMachineCommand(() async {
          final intensity = _lightingIntensity.clamp(0, 100);
          return ref
              .read(diamondCamStateProvider.notifier)
              .setLight(
                on: _lightingEnabled && intensity > 0,
                intensity: intensity,
              );
        }, 'Lighting update failed'),
      );
    });
  }

  Future<void> _switchCamera() async {
    try {
      await ref.read(cameraControllerProvider).switchCamera();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera switching is unavailable right now: ${error.toString()}',
          ),
        ),
      );
    }
  }

  void _changePreset(String presetId) {
    final catalog = ref.read(presetCatalogProvider);
    final preset = catalog.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presetManager.getPreset(presetId),
    );
    setState(() {
      _selectedPresetId = presetId;
      _lightingIntensity = preset.lightIntensity;
      _lightingEnabled = preset.lightOn;
      _look = preset.processingLook;
      _filterStrength = preset.filterStrength;
      _rotationSpeed = preset.machineSpeed.toDouble();
      _captureMode = preset.isVideoPreset
          ? _StudioCaptureMode.video
          : _StudioCaptureMode.photo;
      _sheetExpanded = true;
      _sheetHeight = _sheetMaxHeight;
      _tabController.index = 2;
    });
    _publishLook();
    final diamond = ref.read(diamondCamStateProvider);
    if (diamond.phase != DiamondCamPhase.verified) {
      return;
    }
    unawaited(
      _runMachineCommand(() async {
        return ref
            .read(diamondCamStateProvider.notifier)
            .setLight(on: preset.lightOn, intensity: preset.lightIntensity);
      }, 'Preset lighting setup failed'),
    );
  }

  void _toggleSheet() {
    setState(() {
      _sheetExpanded = !_sheetExpanded;
      _sheetHeight = _sheetExpanded ? _sheetMaxHeight : _sheetMinHeight;
    });
  }

  void _handleSheetDrag(DragUpdateDetails details) {
    setState(() {
      _sheetHeight = (_sheetHeight - details.delta.dy).clamp(
        _sheetMinHeight,
        _sheetMaxHeight,
      );
      _sheetExpanded = _sheetHeight > 220.0;
    });
  }

  void _finalizeSheetDrag(DragEndDetails details) {
    setState(() {
      if (_sheetHeight > 220.0) {
        _sheetExpanded = true;
        _sheetHeight = _sheetMaxHeight;
      } else {
        _sheetExpanded = false;
        _sheetHeight = _sheetMinHeight;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CaptureWorkflowState?>>(
      captureWorkflowStateProvider,
      (previous, next) {
        if (!mounted) return;

        final state = next.asData?.value;
        final previousState = previous?.asData?.value;
        if (state == null || previousState == state) return;

        if (state.stage == CaptureWorkflowStage.capturingPhoto ||
            state.stage == CaptureWorkflowStage.capturing) {
          _setCaptureFeedback('Capturing photo…', show: true, flash: true);
          HapticFeedback.selectionClick();
        }
        if (state.stage == CaptureWorkflowStage.startingVideo) {
          _setCaptureFeedback('Starting recording…', show: true, flash: false);
        }
        if (state.stage == CaptureWorkflowStage.recordingVideo) {
          _setCaptureFeedback('Recording', show: true, flash: false);
        }
        if (state.stage == CaptureWorkflowStage.savingMedia) {
          _setCaptureFeedback('Saving…', show: true, flash: false);
        }
        if (state.hasFailed || state.stage == CaptureWorkflowStage.failed) {
          _setCaptureFeedback(
            state.message.isEmpty ? 'Capture failed' : state.message,
            show: true,
            flash: false,
          );
        }

        if (state.stage == CaptureWorkflowStage.completed) {
          final orchestrator = ref.read(captureOrchestratorProvider);
          final verified =
              orchestrator.latestMediaStoreUri != null &&
              orchestrator.latestMediaStoreUri!.isNotEmpty &&
              orchestrator.latestCapturedFilePath != null &&
              orchestrator.latestCapturedFilePath!.isNotEmpty;
          _setCaptureFeedback(
            orchestrator.latestProcessedPath != null
                ? 'Processed video ready'
                : (verified ? 'Saved to gallery' : 'Capture did not save'),
            show: true,
            flash: false,
          );
          HapticFeedback.mediumImpact();
        }
      },
    );

    final machineUi = ref.watch(diamondCamStateProvider);
    final connectionState = ref.watch(machineConnectionProvider);
    final catalog = ref.watch(presetCatalogProvider);
    final presets = catalog.isEmpty ? _presetManager.builtInPresets : catalog;
    final selectedPreset = presets.firstWhere(
      (p) => p.id == _selectedPresetId,
      orElse: () => presets.first,
    );
    final workflowState = ref.watch(captureWorkflowStateProvider).value;
    final isRecordingVideo =
        workflowState?.stage == CaptureWorkflowStage.recordingVideo;
    final isRunning = (workflowState?.isRunning ?? false) || _captureInFlight;
    final cameraState = ref.watch(cameraStateNotifierProvider);
    final machineConnected =
        connectionState.status == ConnectionStatus.connected;
    final machineStatus = _machineStatusLabel(connectionState);
    final cameraStatus = switch (cameraState.status) {
      CameraLifecycleState.previewActive => 'Camera active',
      CameraLifecycleState.previewStarting => 'Starting camera…',
      CameraLifecycleState.initializing => 'Initializing camera…',
      CameraLifecycleState.permissionRequired => 'Camera permission required',
      CameraLifecycleState.recovering => 'Camera recovering…',
      CameraLifecycleState.unavailable => 'Camera unavailable',
      CameraLifecycleState.error => 'Camera error',
      CameraLifecycleState.disposed => 'Camera disposed',
      _ => 'Camera unavailable',
    };
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetCollapsedHeight = 76.0;
    final sheetExpandedHeight = (screenHeight * 0.6).clamp(240.0, 520.0);
    final sheetHeight = _sheetExpanded
        ? sheetExpandedHeight
        : sheetCollapsedHeight;
    final actionBottomPadding =
        sheetHeight + MediaQuery.of(context).viewPadding.bottom + AppSpacing.m;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go(AppRoutePath.dashboard);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.surface,
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onTapFocus,
                  onScaleUpdate: _onScaleUpdate,
                  child: const CameraPreviewWidget(),
                ),
              ),
              Positioned(
                top: AppSpacing.m,
                left: AppSpacing.m,
                right: AppSpacing.m,
                child: _buildTopBar(
                  context,
                  selectedPreset.name,
                  machineStatus,
                  cameraStatus,
                  machineConnected,
                ),
              ),
              Positioned(
                left: AppSpacing.m,
                right: AppSpacing.m,
                bottom: actionBottomPadding,
                child: _buildActionRow(
                  context,
                  isRunning,
                  isRecordingVideo,
                  cameraState,
                ),
              ),
              Positioned(
                top: 110,
                left: AppSpacing.m,
                right: AppSpacing.m,
                child: AnimatedSwitcher(
                  duration: AppAnimation.fast,
                  child: _buildStatusPill(context, workflowState, isRunning),
                ),
              ),
              if (_captureFlashVisible)
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              if (_captureFeedbackVisible)
                Positioned(
                  top: 160,
                  left: AppSpacing.m,
                  right: AppSpacing.m,
                  child: _buildCaptureFeedback(),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetHeight,
                child: _buildBottomSheet(
                  selectedPreset,
                  presets,
                  cameraState,
                  machineUi,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    dynamic workflowState,
    bool isRunning,
  ) {
    final stage = workflowState?.stage as CaptureWorkflowStage?;
    if (!isRunning &&
        (stage == null ||
            stage == CaptureWorkflowStage.idle ||
            stage == CaptureWorkflowStage.completed)) {
      return const SizedBox.shrink();
    }
    final label = captureWorkflowStageLabel(
      workflowState?.stage,
      fallback: 'Idle',
    );
    final icon = isRunning
        ? Icons.camera_alt_outlined
        : (workflowState?.hasFailed == true
              ? Icons.warning_amber_rounded
              : Icons.camera_alt_outlined);
    final color = isRunning ? AppColors.accentGoldDark : AppColors.surface;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadow.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isRunning ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: isRunning ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureFeedback() {
    return Center(
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadow.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              _captureFeedbackLabel,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String presetLabel,
    String machineStatus,
    String cameraStatus,
    bool connected,
  ) {
    return StudioPanelCard(
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              final popped = await navigator.maybePop();
              if (!popped) {
                router.go(AppRoutePath.dashboard);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presetLabel,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Machine: $machineStatus',
                  style: AppTypography.body.copyWith(
                    color: connected
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Camera: $cameraStatus',
                  style: AppTypography.body.copyWith(
                    color: cameraStatus == 'Camera active'
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutePath.settingsCenter),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    bool isRunning,
    bool isRecordingVideo,
    CameraState cameraState,
  ) {
    final workflowState = ref.watch(captureWorkflowStateProvider).value;
    final orchestrator = ref.read(captureOrchestratorProvider);
    final canPreview =
        workflowState?.stage == CaptureWorkflowStage.completed &&
        (orchestrator.latestProcessedUri != null ||
            orchestrator.latestMediaStoreUri != null);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCaptureModeToggle(),
        if (canPreview) ...[
          const SizedBox(height: AppSpacing.s),
          FilledButton.icon(
            onPressed: _previewLatestExport,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Preview export'),
          ),
        ],
        const SizedBox(height: AppSpacing.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StudioPanelCard(
              child: IconButton(
                onPressed: () => context.push(AppRoutePath.gallery),
                icon: const Icon(Icons.photo_library_outlined),
              ),
            ),
            StudioCaptureButton(
              onTap: _startCapture,
              recording: isRecordingVideo,
              enabled:
                  cameraState.isReady &&
                  !_captureInFlight &&
                  (!isRunning || isRecordingVideo),
              videoMode: _captureMode == _StudioCaptureMode.video,
            ),
            StudioPanelCard(
              child: IconButton(
                onPressed: _toggleSheet,
                icon: const Icon(Icons.menu_open_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheet(
    preset_model.CameraPreset selectedPreset,
    List<preset_model.CameraPreset> presets,
    CameraState cameraState,
    DiamondCamUiState machineUi,
  ) {
    final workflowState = ref.watch(captureWorkflowStateProvider).value;
    return Material(
      elevation: 16,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleSheet,
              onVerticalDragUpdate: _handleSheetDrag,
              onVerticalDragEnd: _finalizeSheetDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'Controls',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _sheetExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_sheetExpanded)
              Expanded(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      onTap: (_) {
                        setState(() {
                          _sheetExpanded = true;
                          _sheetHeight = _sheetMaxHeight;
                        });
                      },
                      indicator: BoxDecoration(
                        color: AppColors.accentGoldLight,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: 'Camera'),
                        Tab(text: 'Machine'),
                        Tab(text: 'Processing'),
                        Tab(text: 'Export'),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: AppSpacing.s,
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StudioPresetSelector(
                                    presets: presets,
                                    selectedPresetId: _selectedPresetId,
                                    onPresetSelected: (value) {
                                      _changePreset(value);
                                      setState(() {
                                        _sheetExpanded = false;
                                        _sheetHeight = _sheetMinHeight;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  _buildCaptureModeToggle(),
                                  const SizedBox(height: AppSpacing.m),
                                  StudioPanelCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Exposure & Zoom',
                                          style: AppTypography.headline
                                              .copyWith(fontSize: 16),
                                        ),
                                        const SizedBox(height: AppSpacing.m),
                                        _buildControlRow(
                                          'Exposure',
                                          cameraState.exposure,
                                          -3.0,
                                          3.0,
                                          _setExposure,
                                        ),
                                        const SizedBox(height: AppSpacing.m),
                                        _buildControlRow(
                                          'Zoom',
                                          _localZoom,
                                          1.0,
                                          8.0,
                                          (value) {
                                            setState(() => _localZoom = value);
                                            ref
                                                .read(cameraControllerProvider)
                                                .zoom
                                                .setZoom(value);
                                            ref
                                                .read(
                                                  cameraStateNotifierProvider
                                                      .notifier,
                                                )
                                                .updateZoom(value);
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.m),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _switchCamera,
                                                icon: const Icon(
                                                  Icons.cameraswitch_outlined,
                                                ),
                                                label: const Text(
                                                  'Switch Camera',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.m),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _cycleFlashMode(
                                                      cameraState.flashMode,
                                                    ),
                                                icon: Icon(
                                                  _flashIcon(
                                                    cameraState.flashMode,
                                                  ),
                                                ),
                                                label: Text(
                                                  'Flash ${_flashLabel(cameraState.flashMode)}',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.s),
                                        OutlinedButton.icon(
                                          onPressed: () => setState(
                                            () => _showAdvancedControls =
                                                !_showAdvancedControls,
                                          ),
                                          icon: Icon(
                                            _showAdvancedControls
                                                ? Icons.tune
                                                : Icons.tune_outlined,
                                          ),
                                          label: Text(
                                            _showAdvancedControls
                                                ? 'Hide advanced controls'
                                                : 'Show advanced controls',
                                          ),
                                        ),
                                        if (_showAdvancedControls) ...[
                                          const SizedBox(height: AppSpacing.m),
                                          _buildAdvancedControls(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  StudioRotationPanel(
                                    onLeft: () => _runMachineCommand(() {
                                      final notifier = ref.read(
                                        diamondCamStateProvider.notifier,
                                      );
                                      notifier.setSelectedAngle(
                                        (machineUi.commandedAngle -
                                                _rotationDegrees)
                                            .clamp(0, 180),
                                      );
                                      notifier.setSelectedSpeed(_rotationSpeed);
                                      return notifier.rotateToSelected();
                                    }, 'Left rotation failed'),
                                    onRight: () => _runMachineCommand(() {
                                      final notifier = ref.read(
                                        diamondCamStateProvider.notifier,
                                      );
                                      notifier.setSelectedAngle(
                                        (machineUi.commandedAngle +
                                                _rotationDegrees)
                                            .clamp(0, 180),
                                      );
                                      notifier.setSelectedSpeed(_rotationSpeed);
                                      return notifier.rotateToSelected();
                                    }, 'Right rotation failed'),
                                    onStop: () => _runMachineCommand(
                                      () => ref
                                          .read(
                                            diamondCamStateProvider.notifier,
                                          )
                                          .stop(),
                                      'Stop command failed',
                                    ),
                                    onContinuousCw: () =>
                                        _runMachineCommand(() {
                                          final notifier = ref.read(
                                            diamondCamStateProvider.notifier,
                                          );
                                          notifier.setSelectedSpeed(
                                            _rotationSpeed,
                                          );
                                          return notifier.continuousCw();
                                        }, 'Continuous CW failed'),
                                    onContinuousCcw: () =>
                                        _runMachineCommand(() {
                                          final notifier = ref.read(
                                            diamondCamStateProvider.notifier,
                                          );
                                          notifier.setSelectedSpeed(
                                            _rotationSpeed,
                                          );
                                          return notifier.continuousCcw();
                                        }, 'Continuous CCW failed'),
                                    onSpeedChanged: (value) =>
                                        setState(() => _rotationSpeed = value),
                                    onDegreesChanged: (value) => setState(
                                      () => _rotationDegrees = value,
                                    ),
                                    speed: _rotationSpeed,
                                    degrees: _rotationDegrees,
                                    busy: _machineBusy || machineUi.busy,
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  StudioLightingPanel(
                                    machinePhase: machineUi.phase,
                                    firmwareLightOn: machineUi.lightOn,
                                    firmwareIntensity: machineUi.intensity,
                                    requestedOn: _lightingEnabled,
                                    requestedIntensity: _lightingIntensity,
                                    busy: _machineBusy || machineUi.busy,
                                    commandMessage: machineUi.message,
                                    onMasterChanged: (value) {
                                      unawaited(_setMasterLight(value));
                                    },
                                    onIntensityChanged: (value) {
                                      setState(
                                        () => _lightingIntensity = value,
                                      );
                                      _queueLightingUpdate();
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  StudioFilterPanel(
                                    look: _look,
                                    strength: _filterStrength,
                                    onLookChanged: (value) {
                                      setState(() => _look = value);
                                      _publishLook();
                                    },
                                    onStrengthChanged: (value) {
                                      setState(() => _filterStrength = value);
                                      _publishLook();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StudioPresetSelector(
                                    presets: presets,
                                    selectedPresetId: _selectedPresetId,
                                    onPresetSelected: _changePreset,
                                  ),
                                  const SizedBox(height: AppSpacing.m),
                                  StudioPanelCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Capture workflow',
                                          style: AppTypography.headline
                                              .copyWith(fontSize: 16),
                                        ),
                                        const SizedBox(height: AppSpacing.s),
                                        Text(
                                          selectedPreset.isVideoPreset
                                              ? '${selectedPreset.advertisingPurpose}. Record applies lighting, rotation, capture, then automatic grading. GPIO 33 only.'
                                              : '${selectedPreset.advertisingPurpose}. Photo is a single shutter capture.',
                                          style: AppTypography.body.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.s),
                                        _buildStatRow(
                                          'Look',
                                          jewelryProcessingLookLabel(_look),
                                        ),
                                        _buildStatRow(
                                          'Aspect',
                                          selectedPreset.aspectRatio,
                                        ),
                                        _buildStatRow(
                                          'Machine',
                                          selectedPreset.requiresMachine
                                              ? 'Required'
                                              : 'Optional',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StudioPanelCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Export defaults',
                                          style: AppTypography.headline
                                              .copyWith(fontSize: 16),
                                        ),
                                        const SizedBox(height: AppSpacing.m),
                                        _buildStatRow(
                                          'Format',
                                          selectedPreset.exportDefaults.format,
                                        ),
                                        const SizedBox(height: AppSpacing.s),
                                        _buildStatRow(
                                          'Quality',
                                          '${(selectedPreset.exportDefaults.quality * 100).round()}%',
                                        ),
                                        const SizedBox(height: AppSpacing.s),
                                        _buildStatRow(
                                          'Resolution',
                                          selectedPreset
                                              .exportDefaults
                                              .resolution,
                                        ),
                                        const SizedBox(height: AppSpacing.m),
                                        _buildStatRow(
                                          'Export',
                                          workflowState?.stage ==
                                                  CaptureWorkflowStage
                                                      .processing
                                              ? 'Processing…'
                                              : (workflowState?.stage ==
                                                        CaptureWorkflowStage
                                                            .completed
                                                    ? 'Ready'
                                                    : 'Waiting for a finished recording'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlRow(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Text(
              value.toStringAsFixed(title == 'Zoom' ? 1 : 0),
              style: AppTypography.label,
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _buildCaptureModeToggle() {
    return SegmentedButton<_StudioCaptureMode>(
      segments: const [
        ButtonSegment(
          value: _StudioCaptureMode.photo,
          icon: Icon(Icons.photo_camera_outlined),
          label: Text('Photo'),
        ),
        ButtonSegment(
          value: _StudioCaptureMode.video,
          icon: Icon(Icons.videocam_outlined),
          label: Text('Video'),
        ),
      ],
      selected: {_captureMode},
      onSelectionChanged: (selection) {
        setState(() => _captureMode = selection.first);
      },
    );
  }

  Widget _buildAdvancedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _onTapFocus,
          icon: const Icon(Icons.center_focus_strong_outlined),
          label: const Text('Auto focus on subject'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Flexible(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _machineStatusLabel(DeviceConnectionState state) {
    switch (state.status) {
      case ConnectionStatus.connected:
        return 'Protocol Verified';
      case ConnectionStatus.connectedUnverified:
        return 'Reachable · Unverified';
      case ConnectionStatus.transportReachable:
        return 'Transport reachable';
      case ConnectionStatus.verifying:
        return 'Verifying';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting';
      case ConnectionStatus.scanning:
        return 'Scanning';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.failure:
      case ConnectionStatus.error:
      case ConnectionStatus.unreachable:
        return 'Error';
      case ConnectionStatus.idle:
        return 'Idle';
    }
  }

  String _flashLabel(String mode) {
    switch (mode) {
      case 'off':
        return 'Off';
      case 'on':
        return 'On';
      case 'torch':
        return 'Torch';
      case 'auto':
      default:
        return 'Auto';
    }
  }

  IconData _flashIcon(String mode) {
    switch (mode) {
      case 'off':
        return Icons.flash_off_outlined;
      case 'on':
        return Icons.flash_on_outlined;
      case 'torch':
        return Icons.highlight_outlined;
      case 'auto':
      default:
        return Icons.flash_auto_outlined;
    }
  }
}
