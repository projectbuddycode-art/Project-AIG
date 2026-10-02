package com.aig.camera

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * PreviewStreamHandler bridges Camera frame bytes to Flutter via EventChannel.
 * It expects CameraXManager to supply encoded JPEG/HEIF frames to its `sendFrame` method.
 * 
 * NOTE: Camera frames arrive on a background thread (camera executor). 
 * EventChannel.success() must be called on the main thread, so all frame delivery
 * is posted to the main thread via Handler.
 */
class PreviewStreamHandler(private val context: Context): EventChannel.StreamHandler {
    private val TAG = "PreviewStreamHandler"
    private var frameCount = 0
    private var firstFrameLogged = false
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun debugLog(message: String) {
        if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.i(TAG, message)
        }
    }

    private var sink: EventChannel.EventSink? = null

    fun sendSessionEvent(event: String, width: Int = 0, height: Int = 0) {
        if (sink == null) return
        mainHandler.post {
            try {
                val map: MutableMap<String, Any> = HashMap()
                map["event"] = event
                map["width"] = width
                map["height"] = height
                sink?.success(map)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending session event to Flutter", e)
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        frameCount = 0
        firstFrameLogged = false
        debugLog("onListen sink=${events != null}")
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        debugLog("onCancel")
        sink = null
        mainHandler.removeCallbacksAndMessages(null)
    }

    fun sendFrame(bytes: ByteArray, width: Int, height: Int) {
        if (sink == null) return
        frameCount += 1
        if (!firstFrameLogged) {
            firstFrameLogged = true
            debugLog("first frame received: width=$width height=$height bytes=${bytes.size}")
        }
        debugLog("sendFrame frameCount=$frameCount width=$width height=$height bytes=${bytes.size} sink=${sink != null}")

        // Early validation before posting to main thread
        if (bytes.size == 0) {
            Log.e(TAG, "sendFrame failed: JPEG bytes are empty")
            return
        }
        if (bytes.size < 4 || bytes[0] != 0xFF.toByte() || bytes[1] != 0xD8.toByte() || bytes[bytes.size - 2] != 0xFF.toByte() || bytes[bytes.size - 1] != 0xD9.toByte()) {
            Log.e(TAG, "sendFrame failed: invalid JPEG frame bytes=${bytes.size}")
            return
        }
        
        if (sink == null) {
            Log.w(TAG, "sendFrame dropped because sink is null")
            return
        }

        // CRITICAL: Post frame delivery to main thread to avoid @UiThread violation
        // Camera analyzer runs on background thread but EventChannel requires main thread
        mainHandler.post {
            try {
                if (sink == null) return@post
                val map: MutableMap<String, Any> = HashMap()
                map["bytes"] = bytes
                map["width"] = width
                map["height"] = height
                sink?.success(map)
                debugLog("sendFrame dispatched on main thread")
            } catch (e: IllegalStateException) {
                Log.w(TAG, "Dropped frame because EventChannel is closed")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending frame to Flutter", e)
            }
        }
    }
}
