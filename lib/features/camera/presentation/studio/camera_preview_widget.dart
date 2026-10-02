import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/providers/camera_providers.dart';
import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/camera_state.dart';
import 'package:aig/features/camera/engines/camera_engine.dart';

enum PreviewUiState { loading, permission, error }

PreviewUiState resolvePreviewUiState({
  required bool hasFrame,
  required bool isStarting,
  Object? startupError,
}) {
  if (hasFrame) {
    return PreviewUiState.loading;
  }
  if (startupError is CameraPermissionException) {
    return PreviewUiState.permission;
  }
  if (startupError != null) {
    return PreviewUiState.error;
  }
  return isStarting ? PreviewUiState.loading : PreviewUiState.loading;
}

/// Production-ready preview widget that renders frames emitted by the
/// `CameraEngine.previewStream`. It decodes encoded image bytes into a
/// `ui.Image` and paints via `RawImage` for compatibility with native engines
/// that will produce JPEG/encoded frames. The widget is intentionally
/// lightweight and does not implement business logic.
class CameraPreviewWidget extends ConsumerStatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  ConsumerState<CameraPreviewWidget> createState() =>
      _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<CameraPreviewWidget>
    with WidgetsBindingObserver {
  StreamSubscription<CameraFrame>? _sub;
  Timer? _startupTimeout;
  ui.Image? _image;
  bool _decoding = false;
  bool _starting = true;
  Future<void>? _startupFuture;
  bool _disposed = false;
  bool _nativePreviewLive = false;
  bool _platformViewReady = false;
  int _sessionVersion = 0;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) return;
      ref.read(cameraStateNotifierProvider.notifier).resetForNewSession();
      _startPreviewSession();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_stopPreviewSession());
        break;
      case AppLifecycleState.resumed:
        _startPreviewSession();
        break;
    }
  }

  Future<void> _stopPreviewSession() async {
    _startupTimeout?.cancel();
    _startupTimeout = null;
    if (_sub != null) {
      await _sub!.cancel();
      _sub = null;
    }
    try {
      await ref.read(cameraControllerProvider).stopPreview();
    } catch (_) {
      // A stale preview may already be torn down. Keep teardown best-effort.
    }
  }

  /// Authoritative camera startup method. Handles permission check and full initialization.
  /// Idempotent: concurrent callers share one in-flight Future.
  Future<void> _ensureCameraActive() {
    if (_startupFuture != null) {
      return _startupFuture!;
    }
    final future = _startCameraSession();
    _startupFuture = future;
    return future.whenComplete(() {
      if (identical(_startupFuture, future)) {
        _startupFuture = null;
      }
    });
  }

  Future<void> _startCameraSession() async {
    if (!mounted || _disposed) return;

    final sessionVersion = ++_sessionVersion;
    debugPrint('[CAMERA] ensureCameraActive starting session #$sessionVersion');
    setState(() {
      _starting = true;
      _startupError = null;
      _nativePreviewLive = false;
    });

    try {
      final camera = ref.read(cameraControllerProvider);

      debugPrint('[CAMERA] #$sessionVersion: Checking camera permission...');
      ref.read(cameraStateNotifierProvider.notifier)
        ..setStatus(CameraLifecycleState.permissionRequired)
        ..setInitialized(false)
        ..setPreviewing(false);

      // Initialize will check permission internally
      await camera.initialize();
      debugPrint(
        '[CAMERA] #$sessionVersion: Camera permission granted or already granted',
      );

      if (!mounted || sessionVersion != _sessionVersion) {
        debugPrint(
          '[CAMERA] #$sessionVersion: Session mismatch during initialization, aborting',
        );
        return;
      }

      if (Platform.isAndroid && !_platformViewReady) {
        debugPrint(
          '[CAMERA] #$sessionVersion: Waiting for native PreviewView before binding',
        );
        ref.read(cameraStateNotifierProvider.notifier)
          ..setStatus(CameraLifecycleState.previewStarting)
          ..setInitialized(true)
          ..setPreviewing(false);
        return;
      }

      debugPrint('[CAMERA] #$sessionVersion: Starting preview...');
      ref.read(cameraStateNotifierProvider.notifier)
        ..setStatus(CameraLifecycleState.previewStarting)
        ..setInitialized(true)
        ..setPreviewing(false);

      await camera.startPreview();

      if (!mounted || sessionVersion != _sessionVersion) {
        debugPrint(
          '[CAMERA] #$sessionVersion: Session mismatch after startPreview, aborting',
        );
        return;
      }

      // Cancel old subscription and set up new one
      if (_sub != null) {
        await _sub!.cancel();
        _sub = null;
      }

      debugPrint('[CAMERA] #$sessionVersion: Subscribing to preview stream...');
      _sub = camera.preview.listen(
        (frame) {
          if (!mounted || sessionVersion != _sessionVersion) {
            debugPrint(
              '[CAMERA] Session mismatch in frame handler, ignoring frame',
            );
            return;
          }

          // Cancel timeout on first frame
          if (_startupTimeout != null) {
            debugPrint(
              '[CAMERA] #$sessionVersion: First frame received! Cancelling startup timeout',
            );
            _startupTimeout?.cancel();
            _startupTimeout = null;
          }

          final bytes = frame.bytes;
          if (bytes == null || bytes.isEmpty) {
            if (!_nativePreviewLive &&
                mounted &&
                sessionVersion == _sessionVersion) {
              setState(() {
                _nativePreviewLive = true;
                _starting = false;
                _startupError = null;
              });
              ref
                  .read(cameraStateNotifierProvider.notifier)
                  .markPreviewActive();
            }
            return;
          }

          _maybeDecode(bytes, frame.width, frame.height);
        },
        onError: (error) {
          debugPrint('[CAMERA] #$sessionVersion: Preview stream error: $error');
          if (!mounted || sessionVersion != _sessionVersion) return;
          setState(() {
            _starting = false;
            _startupError = error;
          });
          ref.read(cameraStateNotifierProvider.notifier)
            ..setStatus(CameraLifecycleState.error)
            ..setInitialized(false)
            ..setPreviewing(false);
        },
        onDone: () {
          debugPrint('[CAMERA] #$sessionVersion: Preview stream closed');
          if (!mounted || sessionVersion != _sessionVersion) return;
          if (_image == null) {
            setState(() {
              _starting = false;
              _startupError = const CameraUnavailableException(
                'Preview stream closed unexpectedly',
              );
            });
            ref.read(cameraStateNotifierProvider.notifier)
              ..setStatus(CameraLifecycleState.unavailable)
              ..setInitialized(false)
              ..setPreviewing(false);
          }
        },
      );

      if (!mounted || sessionVersion != _sessionVersion) {
        debugPrint(
          '[CAMERA] #$sessionVersion: Session mismatch after subscription, aborting',
        );
        return;
      }

      // Keep loading overlay until preview is genuinely active.

      // Set timeout for first frame arrival
      _startupTimeout?.cancel();
      _startupTimeout = Timer(const Duration(seconds: 20), () {
        if (!mounted ||
            sessionVersion != _sessionVersion ||
            _image != null ||
            _startupError != null) {
          debugPrint(
            '[CAMERA] #$sessionVersion: Timeout skipped (image exists or error set or session changed)',
          );
          return;
        }
        debugPrint(
          '[CAMERA] #$sessionVersion: TIMEOUT - No frames received after 20 seconds, attempting recovery...',
        );
        _attemptRecovery(sessionVersion);
      });

      debugPrint(
        '[CAMERA] #$sessionVersion: Preview session started, waiting for first frame...',
      );
    } on CameraPermissionException catch (error) {
      debugPrint('[CAMERA] #$sessionVersion: Permission denied: $error');
      if (!mounted || sessionVersion != _sessionVersion) return;
      setState(() {
        _starting = false;
        _startupError = error;
      });
      ref.read(cameraStateNotifierProvider.notifier)
        ..setStatus(CameraLifecycleState.permissionRequired)
        ..setInitialized(false)
        ..setPreviewing(false);
    } catch (error) {
      debugPrint(
        '[CAMERA] #$sessionVersion: Camera startup error: $error\n${StackTrace.current}',
      );
      if (!mounted || sessionVersion != _sessionVersion) return;
      setState(() {
        _starting = false;
        _startupError = error;
      });
      ref.read(cameraStateNotifierProvider.notifier)
        ..setStatus(CameraLifecycleState.error)
        ..setInitialized(false)
        ..setPreviewing(false);
    }
  }

  /// Attempt recovery if preview doesn't activate after timeout
  Future<void> _attemptRecovery(int expectedSessionVersion) async {
    if (!mounted || expectedSessionVersion != _sessionVersion) return;

    debugPrint('[CAMERA] #$expectedSessionVersion: Attempting recovery...');
    try {
      await _stopPreviewSession();
      // Clear state and retry
      _image = null;
      setState(() {
        _starting = true;
        _startupError = null;
      });

      // Retry the full startup flow
      await _ensureCameraActive();
    } catch (error) {
      debugPrint('[CAMERA] #$expectedSessionVersion: Recovery failed: $error');
      if (!mounted) return;
      setState(() {
        _starting = false;
        _startupError = CameraUnavailableException(
          'Camera unavailable: $error',
        );
      });
      ref.read(cameraStateNotifierProvider.notifier)
        ..setStatus(CameraLifecycleState.unavailable)
        ..setInitialized(false)
        ..setPreviewing(false);
    }
  }

  void _startPreviewSession() {
    // Start camera initialization immediately, handling permission checks automatically
    Future<void>(() => _ensureCameraActive());
  }

  Future<void> _retryStartup() async {
    if (!mounted) return;
    _sessionVersion += 1;
    await _stopPreviewSession();
    _sub?.cancel();
    _sub = null;
    _startupTimeout?.cancel();
    _image = null;
    setState(() {
      _starting = true;
      _startupError = null;
      _image = null;
    });
    ref.read(cameraStateNotifierProvider.notifier).setInitialized(false);
    ref.read(cameraStateNotifierProvider.notifier).setPreviewing(false);
    _startPreviewSession();
  }

  Future<void> _maybeDecode(Uint8List bytes, int width, int height) async {
    if (_decoding || _disposed) return;
    _decoding = true;
    final sessionVersion = _sessionVersion;
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        if (!completer.isCompleted) {
          completer.complete(img);
        }
      });
      final img = await completer.future;
      if (!mounted || _disposed || sessionVersion != _sessionVersion) {
        img.dispose();
        return;
      }
      final previousImage = _image;
      setState(() {
        _image = img;
      });
      previousImage?.dispose();
      if (!mounted || _disposed || sessionVersion != _sessionVersion) {
        img.dispose();
        return;
      }
      ref.read(cameraStateNotifierProvider.notifier).markPreviewActive();
    } catch (_) {
    } finally {
      _decoding = false;
    }
  }

  @override
  void didUpdateWidget(covariant CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // nothing to do; keep subscription
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _sessionVersion += 1;
    _startupTimeout?.cancel();
    _startupTimeout = null;
    _sub?.cancel();
    _sub = null;
    final previousImage = _image;
    _image = null;
    previousImage?.dispose();
    ref
        .read(cameraStateNotifierProvider.notifier)
        .setStatus(CameraLifecycleState.idle);
    unawaited(_stopPreviewSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookPreview = ref.watch(jewelryLookPreviewProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final state = resolvePreviewUiState(
          hasFrame: _image != null || _nativePreviewLive,
          isStarting: _starting,
          startupError: _startupError,
        );

        Widget overlay;
        if (_nativePreviewLive || _image != null) {
          overlay = const SizedBox.shrink();
        } else if (state == PreviewUiState.permission) {
          overlay = _PermissionState(
            onRetry: _retryStartup,
            onOpenSettings: () async {
              try {
                await AppSettings.openAppSettings();
              } catch (_) {}
            },
          );
        } else if (state == PreviewUiState.error) {
          overlay = _CameraPreviewMessage(
            icon: Icons.videocam_off_outlined,
            title: 'Camera unavailable on this device',
            message: 'The camera could not start a live preview session.',
            action: _retryStartup,
          );
        } else {
          overlay = const _PreviewLoadingState();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    jewelryFilterColorMatrix(
                      lookPreview.look,
                      lookPreview.strength,
                    ),
                  ),
                  child: Platform.isAndroid
                      ? AndroidView(
                          viewType: 'aig.camera/preview_view',
                          layoutDirection: TextDirection.ltr,
                          onPlatformViewCreated: (_) {
                            if (_disposed) return;
                            _platformViewReady = true;
                            unawaited(_ensureCameraActive());
                          },
                        )
                      : (_image != null
                            ? FittedBox(
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: _image!.width.toDouble(),
                                  height: _image!.height.toDouble(),
                                  child: RawImage(
                                    image: _image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                ),
                IgnorePointer(
                  child: ColoredBox(
                    color: jewelryFilterOverlay(
                      lookPreview.look,
                      lookPreview.strength,
                    ),
                  ),
                ),
                if (overlay is! SizedBox) overlay,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  const _PreviewLoadingState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                'Starting camera…',
                style: AppTypography.label.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({required this.onRetry, required this.onOpenSettings});

  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                'Camera access is needed',
                style: AppTypography.subtitle.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Allow camera access to capture photos.',
                style: AppTypography.body.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open App Settings'),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewMessage extends StatelessWidget {
  const _CameraPreviewMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
