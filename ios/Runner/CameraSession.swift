import Foundation

/// CameraSession coordinates CameraManager components and lifecycle.
class CameraSession {
    private let manager: CameraManager

    init(manager: CameraManager) {
        self.manager = manager
    }

    func start() {
        manager.initialize()
        manager.startPreview()
    }

    func stop() {
        manager.stopPreview()
        manager.dispose()
    }
}
