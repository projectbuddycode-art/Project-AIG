import 'package:aig/features/camera/controllers/camera_state_controller.dart';
import 'package:aig/features/camera/engines/camera_engine.dart';
import 'package:aig/features/camera/models/camera_state.dart';
import 'package:aig/features/camera/presentation/studio/camera_preview_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preview state resolution', () {
    test('returns permission state for camera permission errors', () {
      final state = resolvePreviewUiState(
        hasFrame: false,
        isStarting: false,
        startupError: const CameraPermissionException('Camera access was denied.'),
      );

      expect(state, PreviewUiState.permission);
    });

    test('returns loading state while waiting for the first frame', () {
      final state = resolvePreviewUiState(
        hasFrame: false,
        isStarting: true,
        startupError: null,
      );

      expect(state, PreviewUiState.loading);
    });

    test('ignores stale preview activation after disposal', () {
      final notifier = CameraStateNotifier();

      notifier.markDisposed();
      notifier.markPreviewActive();

      expect(notifier.state.status, CameraLifecycleState.disposed);
      expect(notifier.state.isPreviewing, isFalse);
    });

    test('resetForNewSession allows a new preview to become active', () {
      final notifier = CameraStateNotifier();
      notifier.markDisposed();
      notifier.resetForNewSession();
      notifier.markPreviewActive();

      expect(notifier.state.status, CameraLifecycleState.previewActive);
      expect(notifier.state.isReady, isTrue);
    });

    test('isReady requires an active preview session', () {
      final notifier = CameraStateNotifier();
      notifier.setInitialized(true);

      expect(notifier.state.status, CameraLifecycleState.previewStarting);
      expect(notifier.state.isReady, isFalse);

      notifier.markPreviewActive();
      expect(notifier.state.isReady, isTrue);
    });
  });
}
