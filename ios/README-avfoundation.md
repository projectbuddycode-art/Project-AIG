iOS AVFoundation scaffolding

Files added under `ios/Runner/`:
- `PlatformCameraPlugin.swift` - registers MethodChannel and EventChannel, delegates to `CameraManager`.
- `CameraManager.swift` - AVFoundation session manager scaffold (session lifecycle, preview, capture, video, focus, exposure, zoom, flash).
- `PreviewStreamHandler.swift` - FlutterStreamHandler that sends frame dictionaries {bytes, width, height}.

Next steps to wire:
1. In `AppDelegate.swift`, register the plugin in `application(_:didFinishLaunchingWithOptions:)`:

```swift
PlatformCameraPlugin.register(with: registrar(forPlugin: "PlatformCameraPlugin"))
```

2. Implement `CameraManager` using AVFoundation: create `AVCaptureSession`, add inputs/outputs, use `AVCaptureVideoDataOutput` and a `CMSampleBuffer` callback to encode frames to JPEG/HEIF before sending to `PreviewStreamHandler.sendFrame`.

3. Ensure thread-safety and minimal allocations when encoding frames; prefer hardware encoders where possible.
