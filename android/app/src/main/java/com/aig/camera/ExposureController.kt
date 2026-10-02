package com.aig.camera

/**
 * ExposureController
 *
 * Controls exposure compensation, manual ISO/shutter in future.
 */
class ExposureController(private val manager: CameraXManager) {
    fun setExposureCompensation(ev: Int) {
        // TODO: Set exposure compensation via CameraControl.setExposureCompensationIndex
    }

    fun lockExposure() {
        // TODO: Lock AE
    }

    fun unlockExposure() {
        // TODO: Unlock AE
    }
}
