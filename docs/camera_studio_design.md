Widget tree

- SafeArea
  - Column (vertical)
    - TopStatusBar (Row)
      - MachineStatusChip (left)
      - PresetSelector (center)
      - Settings/Info (right)
    - Expanded (flex: 8)
      - Stack
        - CameraPreview (StreamBuilder from `cameraController.preview`)
        - GridOverlay / LevelIndicator / Histogram (visual overlays)
        - FocusIndicator (uses CameraState)
        - Floating Left Panel (Rotation controls) -> uses `machineControllerProvider`
        - Floating Right Panel (Lighting controls) -> uses `machineControllerProvider`
        - CaptureOverlay (existing widget) top-right
    - BottomControls (Row)
      - GalleryButton (opens gallery sheet using `galleryManagerProvider`)
      - ModeToggle (Photo/Video) (uses CaptureMode locally)
      - CaptureButton (primary, large) -> triggers `captureOrchestratorProvider.startSession`
      - PresetButton (open preset selector)
      - ExportQueueIndicator (reads `exportStateNotifierProvider`)
    - Expandable BottomSheet (AnimatedContainer)
      - Manual focus, ISO, Exposure, White Balance, Shutter, Resolution, FPS, Zoom, Flash toggles

State flow

- Providers consumed:
  - `cameraControllerProvider` -> control camera actions (preview, capture, focus, zoom)
  - `cameraStateNotifierProvider` -> read/write camera UI state (zoom, focus, exposure)
  - `machineControllerProvider` -> rotation & lighting controls
  - `captureOrchestratorProvider` -> observe workflow via `captureWorkflowStateProvider` and `captureWorkflowEventsProvider`
  - `galleryManagerProvider` / `galleryControllerProvider` -> list/open media
  - `processingPipelineProvider` -> show processing status icon when sessions are active
  - `exportEngineProvider` / `exportStateNotifierProvider` -> show export queue indicator

- UI only observes streams and calls methods on controllers; no business logic implemented in widgets.

Files to create

- `lib/features/camera/presentation/studio/camera_studio_screen.dart` (main screen)

Files to modify

- `lib/core/constants/app_constants.dart` - add route constant
- `lib/core/router/app_router.dart` - add route to the router

Why each file exists

- `camera_studio_screen.dart`: production-grade UI composed of existing controllers/providers and reusable widgets in `presentation/experience`.
- `app_constants.dart`: expose a route path constant so the screen can be reached via navigation consistent with the app.
- `app_router.dart`: register the route so QA/dev can navigate to the studio screen.

Now I'll create the screen and update router/constants. 