import Foundation

/// VideoRecorder manages AVCaptureMovieFileOutput or AVAssetWriter-based recording.
class VideoRecorder {
    func startRecording(outputURL: URL) {
        // TODO: Start recording
    }

    func stopRecording() -> Data? {
        // TODO: Stop recording and optionally return summary bytes
        return nil
    }
}
