package com.aig.camera

/**
 * FocusController
 *
 * Provides manual focus, auto-focus, focus lock/unlock.
 */
class FocusController(private val manager: CameraXManager) {
    fun autoFocus(x: Float, y: Float) {
        // TODO: Implement tap-to-focus using CameraX FocusMeteringAction
    }

    fun setFocusDistance(focusDistance: Float) {
        // TODO: Implement manual focus when supported
    }

    fun lockFocus() {
        // TODO: Lock focus
    }

    fun unlockFocus() {
        // TODO: Unlock focus
    }
}
