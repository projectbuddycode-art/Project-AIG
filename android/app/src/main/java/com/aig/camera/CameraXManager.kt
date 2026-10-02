package com.aig.camera

import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.Image
import android.os.SystemClock
import android.util.Log
import android.util.Range
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.camera.video.PendingRecording
import androidx.camera.video.FallbackStrategy
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * CameraXManager
 *
 * Production-ready CameraX implementation providing preview frames (JPEG bytes),
 * photo capture, video recording, camera switching, zoom, tap-to-focus and exposure control.
 */
class CameraXManager(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val previewHandler: PreviewStreamHandler
) {
    private val TAG = "CameraXManager"

    private fun debugLog(message: String) {
        if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.i(TAG, message)
        }
    }

    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var imageCapture: ImageCapture? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var activeRecording: Recording? = null
    private var pendingStopCallback: ((String?) -> Unit)? = null
    private var currentVideoFile: File? = null
    private var currentCameraSelector: CameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    private var camera: Camera? = null
    private var lastFrameTime = 0L
    private val minFrameIntervalMs = 33L // ~30 FPS
    private var currentFlashMode = "auto"
    private var lastPreviewSurfaceProvider: Preview.SurfaceProvider? = null
    private var isInitializing = false
    private val initializationCallbacks = mutableListOf<(Boolean) -> Unit>()
    private var sessionGeneration = 0
    private var previewBound = false

    fun currentSessionGeneration(): Int = sessionGeneration

    fun initialize(callback: ((Boolean) -> Unit)? = null) {
        if (cameraProvider != null) {
            callback?.invoke(true)
            return
        }

        callback?.let { initializationCallbacks.add(it) }
        if (isInitializing) return

        isInitializing = true
        val providerFuture = ProcessCameraProvider.getInstance(context)
        providerFuture.addListener(Runnable {
            try {
                cameraProvider = providerFuture.get()
                Log.i(TAG, "CAMERA_PROVIDER_READY")
                val hasBackCamera = try {
                    cameraProvider?.hasCamera(currentCameraSelector) == true
                } catch (e: Exception) {
                    Log.e(TAG, "Camera availability check failed", e)
                    false
                }
                if (!hasBackCamera) {
                    Log.e(TAG, "No usable back camera is available on this device")
                    cameraProvider = null
                    isInitializing = false
                    initializationCallbacks.forEach { it(false) }
                    initializationCallbacks.clear()
                    return@Runnable
                }
                debugLog("CameraProvider acquired")
                isInitializing = false
                initializationCallbacks.forEach { it(true) }
                initializationCallbacks.clear()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get CameraProvider", e)
                isInitializing = false
                initializationCallbacks.forEach { it(false) }
                initializationCallbacks.clear()
            }
        }, ContextCompat.getMainExecutor(context))
    }

    fun dispose() {
        sessionGeneration += 1
        previewBound = false
        try {
            cameraProvider?.unbindAll()
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing CameraXManager", e)
        }
        camera = null
        imageCapture = null
        imageAnalysis = null
        videoCapture = null
        lastPreviewSurfaceProvider = null
    }

    fun attachPreviewSurface(previewSurfaceProvider: Preview.SurfaceProvider?, callback: ((Boolean, String?) -> Unit)? = null) {
        if (previewSurfaceProvider != null) {
            lastPreviewSurfaceProvider = previewSurfaceProvider
        }
        if (previewBound && camera != null && lastPreviewSurfaceProvider != null) {
            startPreview(lastPreviewSurfaceProvider, true, callback)
            return
        }
        startPreview(previewSurfaceProvider, false, callback)
    }

    fun startPreview(previewSurfaceProvider: Preview.SurfaceProvider? = null, forceRebind: Boolean = false, callback: ((Boolean, String?) -> Unit)? = null) {
        if (previewSurfaceProvider != null) {
            lastPreviewSurfaceProvider = previewSurfaceProvider
        }
        if (previewBound && camera != null && !forceRebind) {
            callback?.invoke(true, null)
            return
        }
        if (cameraExecutor.isShutdown || cameraExecutor.isTerminated) {
            cameraExecutor = Executors.newSingleThreadExecutor()
        }
        sessionGeneration += 1
        val bindGeneration = sessionGeneration
        if (cameraProvider == null) {
            initialize { success ->
                if (success) {
                    startPreview(previewSurfaceProvider, true, callback)
                } else {
                    callback?.invoke(false, "Camera provider failed to initialize")
                }
            }
            return
        }

        val provider = cameraProvider ?: return
        if (!provider.hasCamera(currentCameraSelector)) {
            Log.e(TAG, "No usable camera is available for selector=$currentCameraSelector")
            callback?.invoke(false, "No usable camera is available on this device")
            return
        }
        imageCapture = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .setFlashMode(cameraXFlashMode(currentFlashMode))
            .build()

        Log.i(TAG, "ANALYSIS_CREATED")
        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888)
            .build()

        imageAnalysis?.setAnalyzer(cameraExecutor, ImageAnalysis.Analyzer { image ->
            val generation = sessionGeneration
            try {
                val now = SystemClock.elapsedRealtime()
                if (generation != sessionGeneration) {
                    image.close()
                    return@Analyzer
                }
                if (now - lastFrameTime < minFrameIntervalMs) {
                    image.close()
                    return@Analyzer
                }
                val jpeg = yuvImageToJpeg(image.image, image.width, image.height, 70)
                if (jpeg != null && generation == sessionGeneration) {
                    previewHandler.sendFrame(jpeg, image.width, image.height)
                    lastFrameTime = now
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error analyzing image", e)
            } finally {
                image.close()
            }
        })

        val recorder = Recorder.Builder()
            .setQualitySelector(
                QualitySelector.fromOrderedList(
                    listOf(Quality.FHD, Quality.HD, Quality.SD),
                    FallbackStrategy.lowerQualityOrHigherThan(Quality.HD),
                ),
            )
            .build()
        videoCapture = try {
            VideoCapture.Builder(recorder)
                .setTargetFrameRate(Range(30, 30))
                .build()
        } catch (e: Exception) {
            Log.w(TAG, "30fps lock unavailable, using device default frame rate", e)
            VideoCapture.Builder(recorder).build()
        }

        var preview: Preview? = null
        if (previewSurfaceProvider != null) {
            preview = Preview.Builder().build()
            preview.setSurfaceProvider(previewSurfaceProvider)
            Log.i(TAG, "Preview SurfaceProvider attached")
        }

        try {
            Log.i(TAG, "CAMERA_UNBOUND")
            provider.unbindAll()
            Log.i(TAG, "BIND_START cameraSelector=$currentCameraSelector preview=${preview != null}")
            // Never bind Preview + ImageAnalysis together. Four concurrent use cases
            // commonly produce a valid MP4 with a black/empty video track.
            camera = if (preview != null) {
                provider.bindToLifecycle(lifecycleOwner, currentCameraSelector, preview, imageCapture, videoCapture)
            } else {
                provider.bindToLifecycle(lifecycleOwner, currentCameraSelector, imageAnalysis, imageCapture, videoCapture)
            }
            
            // CRITICAL: Validate camera binding succeeded
            if (camera == null) {
                Log.e(TAG, "Camera binding returned null - binding likely failed")
                callback?.invoke(false, "Camera binding failed: camera is null")
                return
            }
            
            Log.i(TAG, "BIND_SUCCESS camera=${camera != null} activeCamera=${camera?.cameraInfo != null}")
            if (bindGeneration != sessionGeneration) {
                Log.w(TAG, "Ignoring bind success from stale session")
                callback?.invoke(false, "Stale camera session")
                return
            }
            applyFlashMode(currentFlashMode)
            previewBound = true
            try {
                val meteringFactory = SurfaceOrientedMeteringPointFactory(1f, 1f)
                val point = meteringFactory.createPoint(0.5f, 0.5f)
                val action = FocusMeteringAction.Builder(
                    point,
                    FocusMeteringAction.FLAG_AF or FocusMeteringAction.FLAG_AE,
                )
                    .setAutoCancelDuration(4, java.util.concurrent.TimeUnit.SECONDS)
                    .build()
                camera?.cameraControl?.startFocusAndMetering(action)
            } catch (e: Exception) {
                Log.w(TAG, "Continuous jewelry focus lock was not applied", e)
            }
            debugLog("Preview bind succeeded")
            previewHandler.sendSessionEvent("previewStreaming")
            callback?.invoke(true, null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bind use cases", e)
            camera = null
            previewBound = false
            callback?.invoke(false, e.message)
        }
    }

    fun stopPreview() {
        sessionGeneration += 1
        previewBound = false
        cameraProvider?.unbindAll()
        camera = null
    }

    fun capturePhoto(jpegQuality: Int = 95, callback: (ByteArray?) -> Unit) {
        val ic = imageCapture ?: run { callback(null); return }
        ic.takePicture(ContextCompat.getMainExecutor(context), object : ImageCapture.OnImageCapturedCallback() {
            override fun onCaptureSuccess(imageProxy: ImageProxy) {
                try {
                    val bytes = imageProxyToJpeg(imageProxy, jpegQuality)
                    callback(bytes)
                } catch (e: Exception) {
                    Log.e(TAG, "capturePhoto conversion error", e)
                    callback(null)
                } finally {
                    imageProxy.close()
                }
            }

            override fun onError(exception: ImageCaptureException) {
                Log.e(TAG, "ImageCapture error", exception)
                callback(null)
            }
        })
    }

    fun startVideo(path: String?, callback: (Boolean) -> Unit) {
        val vc = videoCapture ?: run {
            callback(false)
            return
        }
        if (activeRecording != null) {
            Log.w(TAG, "startVideo ignored because a recording is already active")
            callback(false)
            return
        }

        val file = if (!path.isNullOrBlank()) File(path) else File(context.cacheDir, "capture_${System.currentTimeMillis()}.mp4")
        currentVideoFile = file
        val outputOptions = FileOutputOptions.Builder(file).build()
        try {
            imageAnalysis?.clearAnalyzer()
            try {
                val meteringFactory = SurfaceOrientedMeteringPointFactory(1f, 1f)
                val point = meteringFactory.createPoint(0.5f, 0.5f)
                val action = FocusMeteringAction.Builder(
                    point,
                    FocusMeteringAction.FLAG_AF or FocusMeteringAction.FLAG_AE,
                )
                    .disableAutoCancel()
                    .build()
                camera?.cameraControl?.startFocusAndMetering(action)
            } catch (e: Exception) {
                Log.w(TAG, "AE/AF lock during recording was not applied", e)
            }
            var startReported = false
            activeRecording = vc.output.prepareRecording(context, outputOptions)
                .apply {
                    // enable audio if permission exists - app should request RECORD_AUDIO
                    // .withAudioEnabled()
                }
                .start(ContextCompat.getMainExecutor(context)) { event: VideoRecordEvent ->
                    when (event) {
                        is VideoRecordEvent.Start -> {
                            Log.d(TAG, "Recording started")
                            if (!startReported) {
                                startReported = true
                                callback(true)
                            }
                        }
                        is VideoRecordEvent.Finalize -> {
                            val finalFile = currentVideoFile
                            val hasError = event.hasError()
                            val valid = finalFile != null && finalFile.exists() && finalFile.length() > 0 && !hasError
                            Log.d(TAG, "Recording finalized: outputUri=${event.outputResults.outputUri} file=${finalFile?.absolutePath} size=${finalFile?.length() ?: 0} hasError=$hasError valid=$valid")
                            activeRecording = null
                            currentVideoFile = null
                            if (!startReported) {
                                startReported = true
                                callback(false)
                            }
                            pendingStopCallback?.let { stopCallback ->
                                if (valid) {
                                    stopCallback(finalFile?.absolutePath)
                                } else {
                                    stopCallback(null)
                                }
                                pendingStopCallback = null
                            }
                        }
                        else -> {}
                    }
                }
        } catch (e: Exception) {
            Log.e(TAG, "startVideo failed", e)
            activeRecording = null
            currentVideoFile = null
            callback(false)
        }
    }

    fun stopVideo(callback: (String?) -> Unit) {
        if (activeRecording == null) {
            callback(null)
            currentVideoFile = null
            return
        }

        pendingStopCallback = callback
        try {
            activeRecording?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "stopVideo failed", e)
            pendingStopCallback = null
            callback(null)
        }
    }

    fun switchCamera(): Boolean {
        val provider = cameraProvider ?: run {
            initialize()
            return false
        }
        val nextSelector = if (currentCameraSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }

        return try {
            if (!provider.hasCamera(nextSelector)) {
                Log.w(TAG, "Requested camera is unavailable")
                false
            } else {
                currentCameraSelector = nextSelector
                startPreview(lastPreviewSurfaceProvider, true)
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "switchCamera failed", e)
            false
        }
    }

    fun setZoom(zoomRatio: Float) {
        camera?.cameraControl?.setZoomRatio(zoomRatio)
    }

    fun setExposureCompensation(ev: Int): Boolean {
        try {
            val activeCamera = camera ?: return false
            val exposureState = activeCamera.cameraInfo.exposureState
            if (!exposureState.isExposureCompensationSupported) {
                return false
            }
            val range = exposureState.exposureCompensationRange
            val clampedEv = ev.coerceIn(range.lower, range.upper)
            activeCamera.cameraControl.setExposureCompensationIndex(clampedEv)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "setExposureCompensation failed", e)
            return false
        }
    }

    fun setFlashMode(mode: String): Boolean {
        currentFlashMode = when (mode) {
            "off", "on", "torch" -> mode
            else -> "auto"
        }
        return applyFlashMode(currentFlashMode)
    }

    private fun applyFlashMode(mode: String): Boolean {
        return try {
            imageCapture?.flashMode = cameraXFlashMode(mode)
            val activeCamera = camera ?: return true
            if (mode == "torch") {
                if (!activeCamera.cameraInfo.hasFlashUnit()) {
                    return false
                }
                activeCamera.cameraControl.enableTorch(true)
            } else {
                activeCamera.cameraControl.enableTorch(false)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "setFlashMode failed", e)
            false
        }
    }

    private fun cameraXFlashMode(mode: String): Int {
        return when (mode) {
            "off", "torch" -> ImageCapture.FLASH_MODE_OFF
            "on" -> ImageCapture.FLASH_MODE_ON
            else -> ImageCapture.FLASH_MODE_AUTO
        }
    }

    fun autoFocus(x: Float, y: Float) {
        try {
            val factory = SurfaceOrientedMeteringPointFactory(1f, 1f)
            val point = factory.createPoint(x, y)
            val action = FocusMeteringAction.Builder(point, FocusMeteringAction.FLAG_AF)
                .addPoint(point, FocusMeteringAction.FLAG_AE)
                .setAutoCancelDuration(3, java.util.concurrent.TimeUnit.SECONDS)
                .build()
            camera?.cameraControl?.startFocusAndMetering(action)
        } catch (e: Exception) {
            Log.e(TAG, "autoFocus failed", e)
        }
    }

    private fun imageProxyToJpeg(imageProxy: ImageProxy, quality: Int): ByteArray? {
        return when (imageProxy.format) {
            ImageFormat.JPEG -> {
                val buffer = imageProxy.planes[0].buffer
                val bytes = ByteArray(buffer.remaining())
                buffer.get(bytes)
                bytes
            }
            ImageFormat.YUV_420_888 -> yuvImageToJpeg(imageProxy.image, imageProxy.width, imageProxy.height, quality)
            else -> {
                Log.e(TAG, "Unsupported capture format=${imageProxy.format}")
                null
            }
        }
    }

    // Helper to convert YUV_420_888 Image to JPEG bytes using YuvImage (NV21)
    private fun yuvImageToJpeg(image: Image?, width: Int, height: Int, quality: Int): ByteArray? {
        if (image == null || image.format != ImageFormat.YUV_420_888) return null
        return try {
            val yPlane = image.planes[0]
            val uPlane = image.planes[1]
            val vPlane = image.planes[2]

            val yRowStride = yPlane.rowStride
            val yPixelStride = yPlane.pixelStride
            val uRowStride = uPlane.rowStride
            val uPixelStride = uPlane.pixelStride
            val vRowStride = vPlane.rowStride
            val vPixelStride = vPlane.pixelStride

            val nv21 = ByteArray(width * height * 3 / 2)
            val yBuffer = yPlane.buffer
            val uBuffer = uPlane.buffer
            val vBuffer = vPlane.buffer

            // copy Y plane
            if (yPixelStride == 1 && yRowStride == width) {
                yBuffer.get(nv21, 0, width * height)
            } else {
                val rowData = ByteArray(yRowStride)
                var outputIndex = 0
                for (row in 0 until height) {
                    yBuffer.position(row * yRowStride)
                    yBuffer.get(rowData, 0, yRowStride)
                    for (col in 0 until width) {
                        nv21[outputIndex++] = rowData[col * yPixelStride]
                    }
                }
            }

            // copy interleaved VU plane data
            val chromaHeight = height / 2
            val chromaWidth = width / 2
            val rowDataU = ByteArray(uRowStride)
            val rowDataV = ByteArray(vRowStride)
            var outputIndex = width * height
            for (row in 0 until chromaHeight) {
                uBuffer.position(row * uRowStride)
                vBuffer.position(row * vRowStride)
                uBuffer.get(rowDataU, 0, uRowStride)
                vBuffer.get(rowDataV, 0, vRowStride)

                for (col in 0 until chromaWidth) {
                    nv21[outputIndex++] = rowDataV[col * vPixelStride]
                    nv21[outputIndex++] = rowDataU[col * uPixelStride]
                }
            }

            val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
            val baos = ByteArrayOutputStream()
            if (yuvImage.compressToJpeg(Rect(0, 0, width, height), quality, baos)) {
                baos.toByteArray()
            } else {
                Log.e(TAG, "YuvImage.compressToJpeg returned false")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "yuv->jpeg conversion failed", e)
            null
        }
    }
}

