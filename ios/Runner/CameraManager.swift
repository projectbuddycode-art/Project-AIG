import Foundation
import AVFoundation

/// CameraManager encapsulates AVFoundation session and camera operations.
/// This is a scaffold prepared for production: session lifecycle, preview,
/// photo capture, video recording, focus, exposure, zoom, flash.
class CameraManager: NSObject {
    private let previewStream: PreviewStreamHandler
    private var session: AVCaptureSession?

    init(previewStream: PreviewStreamHandler) {
        self.previewStream = previewStream
        super.init()
    }

    func initialize() {
        // TODO: Prepare AVCaptureSession, inputs, outputs, and a sample buffer callback
    }

    func dispose() {
        // TODO: Tear down session
    }

    func startPreview() {
        // TODO: Start running session and push encoded frames to previewStream.sendFrame
    }

    func stopPreview() {
        // TODO: Stop session
    }
}
