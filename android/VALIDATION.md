Android CameraX Validation Guide
=================================

This document describes how to validate the native CameraX implementation on a physical Android device before proceeding to iOS.

Prerequisites
- Install JDK and Android SDK, set `JAVA_HOME` and ensure `adb` is available.
- Connect a physical Android device with Developer Mode + USB debugging enabled.
- Grant camera and microphone permissions when prompted.

Build & Install
1. From your project root, build and install the debug APK:

```powershell
cd android
.\gradlew.bat assembleDebug
.\gradlew.bat installDebug
```

2. Or use Flutter tooling from the repo root:

```powershell
flutter run -d <device-id>
```

Runtime Permissions
- The app must request `CAMERA` and `RECORD_AUDIO` at runtime. Use your preferred Flutter permission plugin (e.g. `permission_handler`) to grant them before testing.

Logs & Diagnostics
- Collect logcat output while reproducing issues:

```powershell
adb logcat -v threadtime > camera_logcat.txt
```

- Collect memory/profile data using `adb shell dumpsys meminfo <package>` and Android Studio profiler.

Validation Checklist
- CAMERA
  - Open the CameraStudio screen and verify the camera opens without crashes.
  - Verify the preview starts and remains smooth; watch `camera_logcat.txt` for errors.
  - Check for dropped frames by enabling verbose logs in `CameraXManager`.

- PHOTO
  - Trigger a photo capture; verify the returned JPEG bytes are valid and viewable.
  - Confirm resolution matches device camera capabilities and metadata is preserved when possible.

- VIDEO
  - Start a recording and stop it; verify the output file is saved and playable.
  - If audio enabled, verify audio/video sync.

- FOCUS & EXPOSURE
  - Tap on different preview areas to trigger focus; watch for focus lock and recovery.
  - Adjust exposure compensation and verify the effect.

- ZOOM & FLASH
  - Test smooth zoom via UI control; validate front/back camera switching.
  - Test `auto`, `on`, and `off` flash modes on devices with flash.

- LIFECYCLE
  - Background the app and bring it back; verify the camera reopens and preview resumes.
  - Rotate the screen; verify the preview and capture orientations behave correctly.

- ERRORS
  - Deny camera permission and verify the app receives an error event or shows a proper message.
  - Simulate interruptions (incoming call) and verify recording or preview handles interruptions gracefully.

Performance
- Monitor CPU and memory during preview and capture. Look for memory growth or spikes.
- If preview shows high CPU, consider replacing YUV->JPEG conversion with a texture/native surface path later.

Troubleshooting Tips
- If preview is black, ensure the `CameraXManager` binds use cases after `ProcessCameraProvider` is ready and the lifecycle owner is valid.
- If JPEG conversion is slow, reduce `minFrameIntervalMs` or offload encoding to a dedicated thread/isolate.

Reporting
- Document any failing checklist items in `android/ISSUES.md` with reproducer steps and collected logs. Include device make/model and Android version.
