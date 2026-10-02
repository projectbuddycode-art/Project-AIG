Camera Module Architecture

Overview
- Purpose: Provide a production-grade, platform-independent camera foundation.
- Native integration: Android -> CameraX, iOS -> AVFoundation via platform channels (planned).
- Temporary Flutter engine: `FlutterCameraEngine` isolated behind `CameraEngine` interface.

High-level components
- CameraEngine (abstract): platform-independent engine surface.
- FlutterCameraEngine: temporary implementation returning preview frames and stubs.
- Controllers: single-responsibility controllers handling capture, focus, exposure, zoom, flash.
- CameraController: high-level orchestration and mediator between UI and subsystem controllers. Communicates with `MachineController` only.
- CameraStateController: Riverpod `StateNotifier` exposing immutable `CameraState`.
- Models: `CameraSettings`, `CaptureSettings`, `CameraCapabilities`, `CameraState`, `CameraFrame`, `CaptureResult`.
- Providers: Riverpod providers exposing the engine, controllers, and camera controller.
- UI: `DevCameraPreviewScreen` - simple preview with capture, switch, flash, zoom, focus indicator.

Integration rules
- Camera -> MachineController only (no direct transport calls).
- All native-specific implementations are behind `CameraEngine`.
- UI uses Riverpod providers and never talks to the engine directly.

Files (to be created)
- lib/features/camera/engines/camera_engine.dart
- lib/features/camera/engines/flutter_camera_engine.dart
- lib/features/camera/models/camera_capabilities.dart
- lib/features/camera/models/camera_frame.dart
- lib/features/camera/models/camera_state.dart
- lib/features/camera/models/camera_settings.dart
- lib/features/camera/models/capture_settings.dart
- lib/features/camera/models/capture_result.dart
- lib/features/camera/controllers/camera_controller.dart
- lib/features/camera/controllers/capture_controller.dart
- lib/features/camera/controllers/focus_controller.dart
- lib/features/camera/controllers/exposure_controller.dart
- lib/features/camera/controllers/zoom_controller.dart
- lib/features/camera/controllers/flash_controller.dart
- lib/features/camera/controllers/camera_state_controller.dart
- lib/features/camera/providers/camera_providers.dart
- lib/features/camera/presentation/dev_camera_preview_screen.dart

Next steps
- Implement the files above with clean interfaces and a temporary Flutter engine.
- Wire providers to `MachineController` (existing provider: `machineControllerProvider`).
- Add the dev preview screen and run `flutter analyze`.

Notes
- No camera-native code will be added now; platform channels will be designed in interfaces for future native implementations.
