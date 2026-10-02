package com.aig.camera

/**
 * PhotoCaptureController
 *
 * Responsible for capturing single photos using CameraX ImageCapture and
 * returning encoded bytes (JPEG/HEIF). Designed for extension to support RAW.
 */
class PhotoCaptureController(private val manager: CameraXManager) {
    fun capturePhoto(jpegQuality: Int = 95): ByteArray? {
        // TODO: Implement capture via CameraX ImageCapture and return encoded bytes.
        return null
    }
}
