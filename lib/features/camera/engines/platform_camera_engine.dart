import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/models/camera_frame.dart';
import 'package:aig/features/camera/models/capture_settings.dart';
import 'package:aig/features/camera/models/capture_result.dart';
import 'package:aig/features/camera/models/camera_capabilities.dart';
import 'package:aig/features/camera/models/camera_settings.dart';

/// Platform-backed CameraEngine implementation using MethodChannel/EventChannel.
///
/// Native platforms (Android/iOS) must implement the corresponding channels:
/// - MethodChannel: 'aig.camera/methods' with methods: initialize, dispose,
///   startPreview, stopPreview, capturePhoto, startVideo, stopVideo, switchCamera,
///   setZoom, setExposureCompensation, autoFocus, setFocusDistance, lockFocus,
///   unlockFocus, setFlashMode, setWhiteBalance, setHdrEnabled, setRawEnabled
/// - EventChannel: 'aig.camera/preview' streaming encoded image bytes (Uint8List)
class PlatformCameraEngine implements CameraEngine {
  static const MethodChannel _channel = MethodChannel('aig.camera/methods');
  static const EventChannel _previewChannel = EventChannel(
    'aig.camera/preview',
  );

  StreamController<CameraFrame>? _previewController;
  StreamSubscription? _previewSub;
  bool _previewSubscriptionActive = false;
  int _previewFrameCount = 0;
  bool _previewFirstFrameLogged = false;
  bool _disposed = false;
  int _sessionId = 0; // Session generation counter to detect stale callbacks

  bool _isPreviewing = false;
  CameraSettings _settings = const CameraSettings();

  PlatformCameraEngine() : _previewController = StreamController.broadcast();

  /// Returns the active preview controller.
  /// CRITICAL: Never creates a new controller if the current one is closed.
  /// A closed controller indicates disposal; creating a new one here would
  /// accept frames from old native callbacks that should be ignored.
  StreamController<CameraFrame> get _activePreviewController {
    if (_previewController == null || _previewController!.isClosed) {
      throw StateError(
        'Preview controller is not active. The engine may be disposed or '
        'frames are arriving after expected lifecycle.',
      );
    }
    return _previewController!;
  }

  @override
  Future<void> initialize() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('ensureCameraPermission') ?? false;
      if (!granted) {
        throw const CameraPermissionException();
      }
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      if (e.code == 'camera_unavailable') {
        throw CameraUnavailableException(
          e.message ?? 'No usable camera is available on this device.',
        );
      }
      throw Exception(
        'Camera initialization failed: ${e.message ?? 'native error'}',
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _sessionId++; // Increment session ID to invalidate all pending callbacks

    try {
      await stopPreview();
      await _previewSub?.cancel();
      _previewSub = null;
      _previewSubscriptionActive = false;
      if (_previewController != null && !_previewController!.isClosed) {
        await _previewController!.close();
      }
      _previewController = null;
      await _channel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      throw Exception('Camera disposal failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Stream<CameraFrame> get previewStream {
    if (_disposed) {
      throw StateError(
        'Camera engine is disposed and cannot stream preview frames.',
      );
    }
    _ensureListening();
    // CRITICAL: The previewStream must ONLY be listened to BEFORE dispose() is called.
    // After dispose(), the controller is closed and no new streams can be created.
    return _activePreviewController.stream;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _ensureListening() {
    if (_previewSub != null) {
      _debugLog('[CameraEngine] EventChannel listen already active');
      return;
    }
    _debugLog('[CameraEngine] EventChannel listen started');
    final currentSessionId = _sessionId; // Capture current session ID

    _previewSub = _previewChannel.receiveBroadcastStream().listen(
      (event) {
        // CRITICAL: Reject events from previous sessions to prevent stale callbacks
        if (currentSessionId != _sessionId) {
          _debugLog(
            '[CameraEngine] Ignoring frame from previous session (stale callback)',
          );
          return;
        }

        if (!_previewSubscriptionActive) {
          _previewSubscriptionActive = true;
          _debugLog('[CameraEngine] EventChannel subscription active');
        }
        _previewFrameCount += 1;
        _debugLog(
          '[CameraEngine] EventChannel event received type=${event.runtimeType} frameCount=$_previewFrameCount',
        );

        try {
          // Additional safety: if disposed, don't process events
          if (_disposed ||
              _previewController == null ||
              _previewController!.isClosed) {
            _debugLog(
              '[CameraEngine] Engine disposed or controller closed, dropping frame',
            );
            return;
          }

          if (event == null) {
            _debugLog('[CameraEngine] EventChannel event is null');
            return;
          }
          if (event is Map) {
            final eventName = event['event'];
            if (eventName == 'previewStreaming') {
              _debugLog('[CameraEngine] Native previewStreaming confirmed');
              try {
                _activePreviewController.add(
                  CameraFrame(
                    timestamp: DateTime.now(),
                    bytes: Uint8List(0),
                    width: event['width'] is int ? event['width'] as int : 0,
                    height: event['height'] is int ? event['height'] as int : 0,
                  ),
                );
              } catch (e) {
                _debugLog(
                  '[CameraEngine] Failed to add previewStreaming marker: $e',
                );
              }
              return;
            }
            final dynamic raw = event['bytes'];
            final bytes = raw is Uint8List
                ? raw
                : (raw is List
                      ? Uint8List.fromList(List<int>.from(raw))
                      : null);
            final int width = event['width'] is int ? event['width'] as int : 0;
            final int height = event['height'] is int
                ? event['height'] as int
                : 0;
            _debugLog(
              '[CameraEngine] EventChannel parsed frame width=$width height=$height bytes=${bytes?.length ?? 0}',
            );
            if (!_previewFirstFrameLogged) {
              _previewFirstFrameLogged = true;
              _debugLog(
                '[CameraEngine] first frame received from native preview stream',
              );
            }

            // Safe add with guard
            try {
              _activePreviewController.add(
                CameraFrame(
                  timestamp: DateTime.now(),
                  bytes: bytes,
                  width: width,
                  height: height,
                ),
              );
            } catch (e) {
              _debugLog('[CameraEngine] Failed to add frame to controller: $e');
              // Frame added to closed controller - this should not happen with proper lifecycle
            }
          } else if (event is Uint8List) {
            if (!_previewFirstFrameLogged) {
              _previewFirstFrameLogged = true;
              _debugLog(
                '[CameraEngine] first raw Uint8List frame received from native preview stream',
              );
            }
            _debugLog(
              '[CameraEngine] EventChannel raw Uint8List frame length=${event.length}',
            );

            try {
              _activePreviewController.add(
                CameraFrame(
                  timestamp: DateTime.now(),
                  bytes: event,
                  width: 0,
                  height: 0,
                ),
              );
            } catch (e) {
              _debugLog(
                '[CameraEngine] Failed to add raw frame to controller: $e',
              );
            }
          } else {
            _debugLog(
              '[CameraEngine] EventChannel unexpected event type: ${event.runtimeType}',
            );
          }
        } catch (e, stack) {
          _debugLog('[CameraEngine] EventChannel parse exception: $e\n$stack');
        }
      },
      onError: (error) {
        // Session check before processing error
        if (currentSessionId != _sessionId) {
          _debugLog('[CameraEngine] Ignoring error from previous session');
          return;
        }
        _debugLog('[CameraEngine] EventChannel error: $error');
      },
      onDone: () {
        // Session check before processing done
        if (currentSessionId != _sessionId) {
          _debugLog('[CameraEngine] Ignoring onDone from previous session');
          return;
        }
        _debugLog('[CameraEngine] EventChannel done');
        _previewSubscriptionActive = false;
        _previewSub = null;
      },
    );
  }

  @override
  bool get isPreviewing => _isPreviewing && !_disposed;

  @override
  Future<void> startPreview() async {
    _ensureListening();
    if (_disposed) {
      throw StateError('Camera engine is disposed and cannot start preview.');
    }
    if (_isPreviewing) {
      await _channel.invokeMethod('attachPreviewSurface');
      return;
    }
    try {
      final granted =
          await _channel.invokeMethod<bool>('ensureCameraPermission') ?? false;
      if (!granted) {
        throw const CameraPermissionException();
      }
      await _channel.invokeMethod('startPreview');
      _isPreviewing = true;
    } on PlatformException catch (e) {
      if (e.code == 'camera_unavailable') {
        throw CameraUnavailableException(
          e.message ?? 'No usable camera is available on this device.',
        );
      }
      throw Exception(
        'Camera preview failed to start: ${e.message ?? 'native error'}',
      );
    }
  }

  @override
  Future<void> stopPreview() async {
    if (!_isPreviewing) return;
    try {
      await _channel.invokeMethod('stopPreview');
    } on PlatformException catch (e) {
      throw Exception(
        'Camera preview failed to stop: ${e.message ?? 'native error'}',
      );
    }
    _isPreviewing = false;
  }

  @override
  Future<CaptureResult> capturePhoto(CaptureSettings settings) async {
    try {
      final args = {
        'jpegQuality': settings.jpegQuality,
        'enableRaw': settings.enableRaw,
        'targetWidth': settings.targetWidth,
        'targetHeight': settings.targetHeight,
      };
      final dynamic res = await _channel.invokeMethod('capturePhoto', args);
      if (res is Uint8List) {
        return CaptureResult(
          timestamp: DateTime.now(),
          jpeg: res,
          width: settings.targetWidth,
          height: settings.targetHeight,
        );
      }
      throw StateError(
        'The native camera layer did not return the captured image.',
      );
    } on PlatformException catch (e) {
      throw Exception('Photo capture failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Future<void> startVideo(CaptureSettings settings) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDirectory = Directory('${directory.path}/captures');
      await videoDirectory.create(recursive: true);
      final path =
          '${videoDirectory.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await _channel.invokeMethod('startVideo', <String, dynamic>{
        'path': path,
        'settings': {'jpegQuality': settings.jpegQuality},
      });
    } on PlatformException catch (e) {
      throw Exception(
        'Video recording failed to start: ${e.message ?? 'native error'}',
      );
    }
  }

  @override
  Future<CaptureResult> stopVideo() async {
    try {
      final dynamic res = await _channel.invokeMethod('stopVideo');
      if (res is Uint8List) {
        return CaptureResult(timestamp: DateTime.now(), jpeg: res);
      }
      if (res is String && res.isNotEmpty) {
        final file = File(res);
        if (!file.existsSync() || file.lengthSync() <= 0) {
          throw StateError('Video recording finalized without a valid file.');
        }
        return CaptureResult(timestamp: DateTime.now(), videoPath: res);
      }
      throw StateError(
        'Video recording completed without a valid output path.',
      );
    } on PlatformException catch (e) {
      throw Exception(
        'Video recording failed to stop: ${e.message ?? 'native error'}',
      );
    }
  }

  @override
  Future<void> switchCamera() async {
    try {
      final switched =
          await _channel.invokeMethod<bool>('switchCamera') ?? true;
      if (!switched) {
        throw StateError('Requested camera is unavailable.');
      }
      if (switched) {
        _settings = _settings.copyWith(
          activeLens: _settings.activeLens == 'back' ? 'front' : 'back',
        );
      }
    } on PlatformException catch (e) {
      throw Exception('Camera switch failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Future<void> setZoom(double zoom) async {
    try {
      await _channel.invokeMethod('setZoom', {'zoom': zoom});
      _settings = _settings.copyWith(zoom: zoom);
    } on PlatformException catch (e) {
      throw Exception('Zoom change failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Future<void> setExposureCompensation(double value) async {
    try {
      final applied =
          await _channel.invokeMethod<bool>('setExposureCompensation', {
            'ev': value.round(),
          }) ??
          true;
      if (!applied) {
        throw StateError('Exposure compensation is unavailable.');
      }
      if (applied) {
        _settings = _settings.copyWith(exposureCompensation: value);
      }
    } on PlatformException catch (e) {
      throw Exception('Exposure change failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Future<void> autoFocus({double x = 0.5, double y = 0.5}) async {
    try {
      await _channel.invokeMethod('autoFocus', {'x': x, 'y': y});
      _settings = _settings.copyWith(focusDistance: (x + y) / 2);
    } on PlatformException catch (e) {
      throw Exception('Auto focus failed: ${e.message ?? 'native error'}');
    }
  }

  @override
  Future<void> setFlashMode(String mode) async {
    try {
      final applied =
          await _channel.invokeMethod<bool>('setFlashMode', {'mode': mode}) ??
          true;
      if (!applied) {
        throw StateError('Flash mode is unavailable.');
      }
      if (applied) {
        _settings = _settings.copyWith(flashMode: mode);
      }
    } on PlatformException catch (e) {
      throw Exception(
        'Flash mode change failed: ${e.message ?? 'native error'}',
      );
    }
  }

  // The remainder of the CameraEngine contract related to settings can be
  // implemented by forwarding to the method channel. They are no-ops if not
  // implemented on the native side.
  @override
  CameraCapabilities get capabilities =>
      const CameraCapabilities(hasFlash: true);

  @override
  CameraSettings get settings => _settings;
}
