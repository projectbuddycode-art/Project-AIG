package com.aig.camera

/**
 * CameraSession
 *
 * High-level abstraction that coordinates camera lifecycle and components.
 * Production implementations manage CameraX lifecycle and coordinate controllers.
 */
class CameraSession(private val manager: CameraXManager) {
    fun start() {
        manager.initialize()
        manager.startPreview()
    }

    fun stop() {
        manager.stopPreview()
        manager.dispose()
    }
}
