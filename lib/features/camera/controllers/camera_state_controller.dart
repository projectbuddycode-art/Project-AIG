import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/features/camera/models/camera_state.dart';

class CameraStateNotifier extends StateNotifier<CameraState> {
  CameraStateNotifier() : super(const CameraState.uninitialized());

  bool get _isDisposed => state.status == CameraLifecycleState.disposed;

  void setStatus(CameraLifecycleState status) {
    if (_isDisposed) return;
    state = state.copyWith(status: status);
  }

  void setInitialized(bool v) {
    if (_isDisposed) return;
    state = state.copyWith(
      isInitialized: v,
      status: v
          ? CameraLifecycleState.previewStarting
          : CameraLifecycleState.unavailable,
    );
  }

  void resetForNewSession() {
    state = const CameraState.uninitialized();
  }

  void setPreviewing(bool v) {
    if (_isDisposed) return;
    final nextStatus = v
        ? CameraLifecycleState.previewActive
        : (state.status == CameraLifecycleState.previewActive
              ? CameraLifecycleState.previewStarting
              : state.status);
    state = state.copyWith(isPreviewing: v, status: nextStatus);
  }

  void markPreviewActive() {
    if (_isDisposed) return;
    state = state.copyWith(
      isInitialized: true,
      isPreviewing: true,
      status: CameraLifecycleState.previewActive,
    );
  }

  void markError(Object error) {
    if (_isDisposed) return;
    state = state.copyWith(
      isInitialized: false,
      isPreviewing: false,
      status: CameraLifecycleState.error,
    );
  }

  void markDisposed() => state = state.copyWith(
    isInitialized: false,
    isPreviewing: false,
    status: CameraLifecycleState.disposed,
  );

  void updateZoom(double zoom) {
    if (_isDisposed) return;
    state = state.copyWith(zoom: zoom);
  }

  void updateFocus(double focus) {
    if (_isDisposed) return;
    state = state.copyWith(focus: focus);
  }

  void updateExposure(double exposure) {
    if (_isDisposed) return;
    state = state.copyWith(exposure: exposure);
  }

  void updateFlashMode(String flashMode) {
    if (_isDisposed) return;
    state = state.copyWith(flashMode: flashMode);
  }
}
