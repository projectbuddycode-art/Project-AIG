@file:OptIn(UnstableApi::class)

package com.aig.camera

import android.Manifest
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.embedding.engine.FlutterEngine
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.view.View
import android.view.ViewGroup
import androidx.camera.view.PreviewView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import androidx.media3.common.util.UnstableApi
import io.flutter.plugin.common.BinaryMessenger

/**
 * PlatformCameraPlugin
 *
 * Registers MethodChannel and EventChannel and delegates to CameraXManager.
 */
internal var cameraPermissionPluginInstance: PlatformCameraPlugin? = null

internal fun handleCameraPermissionResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    return cameraPermissionPluginInstance?.onRequestPermissionsResult(requestCode, permissions, grantResults) ?: false
}

class PlatformCameraPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    internal lateinit var methodChannel: MethodChannel
    internal lateinit var previewChannel: EventChannel
    internal var cameraManager: CameraXManager? = null
    internal var previewHandler: PreviewStreamHandler? = null
    internal var activePreviewView: PreviewView? = null
    internal var activeActivity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private val cameraPermissionRequestCode = 4101
    private var flutterBinding: FlutterPlugin.FlutterPluginBinding? = null
    private val permissionResultListener = io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener { requestCode, permissions, grantResults ->
        if (requestCode != cameraPermissionRequestCode) return@RequestPermissionsResultListener false
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        true
    }
    
    fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode != cameraPermissionRequestCode) return false
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        cameraPermissionPluginInstance = this
        flutterBinding = binding
        methodChannel = MethodChannel(binding.binaryMessenger, "aig.camera/methods")
        methodChannel.setMethodCallHandler(this)

        binding.platformViewRegistry.registerViewFactory(
            "aig.camera/preview_view",
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    val previewView = PreviewView(context)
                    previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                    previewView.scaleType = PreviewView.ScaleType.FILL_CENTER
                    activePreviewView = previewView
                    previewView.layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                    )
                    val owner = activeActivity as? androidx.lifecycle.LifecycleOwner
                    if (owner != null) {
                        previewView.previewStreamState.observe(owner) { state ->
                            if (state == PreviewView.StreamState.STREAMING) {
                                previewHandler?.sendSessionEvent(
                                    "previewStreaming",
                                    previewView.width,
                                    previewView.height,
                                )
                            }
                        }
                    }
                    return object : PlatformView {
                        override fun getView(): View = previewView

                        override fun dispose() {
                            if (activePreviewView === previewView) {
                                activePreviewView = null
                            }
                        }
                    }
                }
            },
        )

        previewChannel = EventChannel(binding.binaryMessenger, "aig.camera/preview")
        previewHandler = PreviewStreamHandler(binding.applicationContext)
        previewChannel.setStreamHandler(previewHandler)
        // cameraManager will be created when activity is attached so we have a LifecycleOwner
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cameraPermissionPluginInstance = null
        methodChannel.setMethodCallHandler(null)
        previewChannel.setStreamHandler(null)
        cameraManager?.dispose()
        cameraManager = null
        previewHandler = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ensureCameraPermission" -> ensureCameraPermission(result)
            "initialize" -> {
                ensureCameraManager()?.initialize { success ->
                    if (success) {
                        result.success(null)
                    } else {
                        result.error("camera_unavailable", "No usable camera is available on this device", null)
                    }
                } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "dispose" -> {
                cameraManager?.dispose()
                result.success(null)
            }
            "startPreview" -> {
                cameraManager?.startPreview(activePreviewView?.surfaceProvider) { success, message ->
                    if (success) {
                        result.success(null)
                    } else {
                        result.error("camera_unavailable", message ?: "Camera preview failed to start", null)
                    }
                } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "attachPreviewSurface" -> {
                cameraManager?.attachPreviewSurface(activePreviewView?.surfaceProvider) { success, message ->
                    if (success) {
                        result.success(null)
                    } else {
                        result.error("camera_unavailable", message ?: "Camera preview surface could not be attached", null)
                    }
                } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "stopPreview" -> {
                cameraManager?.stopPreview()
                result.success(null)
            }
            "capturePhoto" -> {
                val jpegQuality = (call.argument<Int>("jpegQuality") ?: 95)
                cameraManager?.capturePhoto(jpegQuality) { bytes ->
                    result.success(bytes)
                } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "startVideo" -> {
                val path = call.argument<String>("path")
                cameraManager?.startVideo(path) { started ->
                    if (started) {
                        result.success(null)
                    } else {
                        result.error("video_unavailable", "Video recording could not be started", null)
                    }
                } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "stopVideo" -> {
                cameraManager?.stopVideo { filePath -> result.success(filePath) } ?: result.error("no_manager", "Camera manager not initialized", null)
            }
            "publishToMediaStore" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val mediaType = call.argument<String>("mediaType")
                val displayName = call.argument<String>("displayName")
                if (sourcePath.isNullOrBlank() || mediaType.isNullOrBlank() || displayName.isNullOrBlank()) {
                    result.error("invalid_media", "sourcePath, mediaType, and displayName are required", null)
                } else {
                    MediaStorePublisher.publish(
                        context = activeActivity?.applicationContext ?: flutterBinding?.applicationContext,
                        sourcePath = sourcePath,
                        mediaType = mediaType,
                        displayName = displayName,
                    )?.let(result::success)
                        ?: result.error("media_store_failed", "MediaStore insertion or finalization failed", null)
                }
            }
            "inspectJewelryVideo" -> {
                val sourcePath = call.argument<String>("sourcePath")
                if (sourcePath.isNullOrBlank()) {
                    result.error("invalid_inspect", "sourcePath is required", null)
                } else {
                    Thread {
                        val payload = JewelryVideoProcessor.inspect(sourcePath)
                        Handler(android.os.Looper.getMainLooper()).post {
                            result.success(payload)
                        }
                    }.start()
                }
            }
            "processJewelryVideo" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val outputPath = call.argument<String>("outputPath")
                val look = call.argument<String>("look") ?: "original"
                val aspectRatio = call.argument<String>("aspectRatio") ?: "1:1"
                val background = call.argument<String>("background") ?: "darkened"
                val allowUpscale = call.argument<Boolean>("allowUpscale") ?: false
                val strength = call.argument<Int>("strength") ?: 70
                val context = activeActivity?.applicationContext ?: flutterBinding?.applicationContext
                if (sourcePath.isNullOrBlank() || outputPath.isNullOrBlank() || context == null) {
                    result.error("invalid_process", "sourcePath, outputPath, and context are required", null)
                } else {
                    Thread {
                        val payload = try {
                            JewelryVideoProcessor.process(
                                context = context,
                                sourcePath = sourcePath,
                                outputPath = outputPath,
                                look = look,
                                aspectRatio = aspectRatio,
                                background = background,
                                allowUpscale = allowUpscale,
                                strength = strength,
                            )
                        } catch (error: Exception) {
                            mapOf(
                                "success" to false,
                                "message" to (error.message ?: "Processing failed"),
                            )
                        }
                        Handler(android.os.Looper.getMainLooper()).post {
                            result.success(payload)
                        }
                    }.start()
                }
            }
            "openMedia" -> {
                val uriValue = call.argument<String>("uri")
                val mimeType = call.argument<String>("mimeType") ?: "*/*"
                val activity = activeActivity
                if (uriValue.isNullOrBlank() || activity == null) {
                    result.error("open_media_failed", "Media URI or activity is unavailable", null)
                } else {
                    try {
                        activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(Uri.parse(uriValue), mimeType)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        })
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("open_media_failed", error.message, null)
                    }
                }
            }
            "switchCamera" -> {
                result.success(cameraManager?.switchCamera() ?: false)
            }
            "setZoom" -> {
                val z = call.argument<Double>("zoom")?.toFloat() ?: 1.0f
                cameraManager?.setZoom(z)
                result.success(null)
            }
            "setExposureCompensation" -> {
                val ev = call.argument<Int>("ev") ?: 0
                result.success(cameraManager?.setExposureCompensation(ev) ?: false)
            }
            "autoFocus" -> {
                val x = call.argument<Double>("x")?.toFloat() ?: 0.5f
                val y = call.argument<Double>("y")?.toFloat() ?: 0.5f
                cameraManager?.autoFocus(x, y)
                result.success(null)
            }
            "setFlashMode" -> {
                val mode = call.argument<String>("mode") ?: "auto"
                result.success(cameraManager?.setFlashMode(mode) ?: false)
            }
            else -> result.notImplemented()
        }
    }

    // ActivityAware
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activeActivity = binding.activity
        binding.addRequestPermissionsResultListener(permissionResultListener)
        // CameraX is created only when Flutter calls initialize from Camera Studio.
    }

    private fun ensureCameraManager(): CameraXManager? {
        val activity = activeActivity ?: activityBinding?.activity
        val lifecycleOwner = activity as? androidx.lifecycle.LifecycleOwner
        val handler = previewHandler
        if (activity == null || lifecycleOwner == null || handler == null) {
            return null
        }
        if (cameraManager == null) {
            cameraManager = CameraXManager(activity.applicationContext, lifecycleOwner, handler)
        }
        return cameraManager
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = null
        activeActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(permissionResultListener)
        activityBinding = null
        activeActivity = null
    }

    internal fun ensureCameraPermission(result: MethodChannel.Result) {
        val activity = activityBinding?.activity ?: activeActivity
        if (activity == null) {
            result.error("no_activity", "Camera permission requires an active activity", null)
            return
        }

        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("permission_pending", "Camera permission request already in progress", null)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.CAMERA), cameraPermissionRequestCode)
    }
}
