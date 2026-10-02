Android CameraX scaffolding

Files added under `android/app/src/main/java/com/aig/camera/`:
- `PlatformCameraPlugin.kt` - Flutter plugin entry point; registers MethodChannel and EventChannel and forwards calls to CameraXManager.
- `CameraXManager.kt` - Encapsulates CameraX lifecycle and responsibilities (preview, capture, video, focus, exposure, zoom).
- `PreviewStreamHandler.kt` - EventChannel stream handler that sends frame maps {bytes, width, height}.

Next steps to wire:
1. Add CameraX dependencies to `android/app/build.gradle`:

```gradle
dependencies {
    implementation "androidx.camera:camera-core:1.3.0"
    implementation "androidx.camera:camera-camera2:1.3.0"
    implementation "androidx.camera:camera-lifecycle:1.3.0"
    implementation "androidx.camera:camera-view:1.3.0"
}
```

2. Register `PlatformCameraPlugin` in your `MainActivity` by calling `PlatformCameraPlugin.registerWith(registrarFor("com.aig.camera.PlatformCameraPlugin"))` or by converting MainActivity to `FlutterActivity` and ensuring plugin auto-registration.

3. Implement CameraXManager using CameraX APIs. Ensure frames are encoded to JPEG/HEIF when sending over EventChannel to minimize Dart-side decoding cost.
