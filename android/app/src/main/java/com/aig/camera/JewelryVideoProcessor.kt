package com.aig.camera

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.Shader
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.Brightness
import androidx.media3.effect.Contrast
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.Presentation
import androidx.media3.effect.RgbAdjustment
import androidx.media3.effect.TextureOverlay
import androidx.media3.transformer.Composition
import com.google.common.collect.ImmutableList
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@UnstableApi
object JewelryVideoProcessor {
    fun inspect(sourcePath: String): Map<String, Any> {
        val source = File(sourcePath)
        if (!source.exists() || source.length() < 8192L) {
            return mapOf("valid" to false, "message" to "Source video is missing or empty", "sizeBytes" to source.length())
        }
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(source.absolutePath)
            val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
            val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
            val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toIntOrNull() ?: 0
            val mime = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE) ?: "video/mp4"
            val fps = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CAPTURE_FRAMERATE)?.toFloatOrNull() ?: 30f
            val valid = width > 0 && height > 0 && durationMs >= 400L
            mapOf(
                "valid" to valid,
                "message" to if (valid) "Readable video stream" else "Video metadata is incomplete",
                "path" to source.absolutePath,
                "width" to width,
                "height" to height,
                "durationMs" to durationMs,
                "rotation" to rotation,
                "bitrate" to bitrate,
                "sizeBytes" to source.length(),
                "frameRate" to fps,
                "mimeType" to mime,
            )
        } catch (error: Exception) {
            mapOf(
                "valid" to false,
                "message" to (error.message ?: "Unable to inspect video"),
                "sizeBytes" to source.length(),
            )
        } finally {
            retriever.release()
        }
    }

    fun process(
        context: Context,
        sourcePath: String,
        outputPath: String,
        look: String,
        aspectRatio: String,
        background: String,
        allowUpscale: Boolean,
        strength: Int,
    ): Map<String, Any> {
        val inspection = inspect(sourcePath)
        if (inspection["valid"] != true) {
            return mapOf(
                "success" to false,
                "message" to (inspection["message"] ?: "Source video is not readable"),
            )
        }
        val dest = File(outputPath)
        dest.parentFile?.mkdirs()
        if (dest.exists()) dest.delete()

        val width = (inspection["width"] as? Number)?.toInt() ?: 0
        val height = (inspection["height"] as? Number)?.toInt() ?: 0
        val outputEdge = squareEdge(width, height, allowUpscale)

        val latch = CountDownLatch(1)
        var error: String? = null
        val main = Handler(Looper.getMainLooper())
        main.post {
            try {
                val edited = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(File(sourcePath))))
                    .setEffects(Effects(listOf(), effectsFor(look, aspectRatio, background, outputEdge, strength)))
                    .build()
                val transformer = Transformer.Builder(context.applicationContext)
                    .setVideoMimeType(MimeTypes.VIDEO_H264)
                    .addListener(object : Transformer.Listener {
                        override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                            latch.countDown()
                        }

                        override fun onError(
                            composition: Composition,
                            exportResult: ExportResult,
                            exportException: ExportException,
                        ) {
                            error = exportException.message ?: "Transformer export failed"
                            latch.countDown()
                        }
                    })
                    .build()
                transformer.start(
                    Composition.Builder(EditedMediaItemSequence(edited)).build(),
                    dest.absolutePath,
                )
            } catch (e: Exception) {
                error = e.message ?: "Transformer could not start"
                latch.countDown()
            }
        }

        val finished = latch.await(180, TimeUnit.SECONDS)
        if (!finished) {
            return mapOf(
                "success" to false,
                "message" to "Processing timed out after 180s. Original recording kept.",
            )
        }
        if (error != null || !dest.exists() || dest.length() < 8192L) {
            return mapOf(
                "success" to false,
                "message" to (error ?: "Processed file was empty. Original recording kept."),
            )
        }
        val verify = inspect(dest.absolutePath)
        if (verify["valid"] != true) {
            dest.delete()
            return mapOf(
                "success" to false,
                "message" to "Processed file was not a readable video. Original recording kept.",
            )
        }
        val outW = (verify["width"] as? Number)?.toInt() ?: outputEdge
        val outH = (verify["height"] as? Number)?.toInt() ?: outputEdge
        val upscaled = allowUpscale && (width < 1080 || height < 1080)
        return mapOf(
            "success" to true,
            "outputPath" to dest.absolutePath,
            "width" to outW,
            "height" to outH,
            "durationMs" to (verify["durationMs"] ?: 0),
            "message" to finishMessage(look, background, outW, outH, upscaled),
        )
    }

    private fun finishMessage(look: String, background: String, width: Int, height: Int, upscaled: Boolean): String {
        val bg = if (background == "darkened") {
            "Darkened vignette applied. This is not jewelry cut-out / background removal."
        } else {
            "Original background retained."
        }
        val scale = if (upscaled) " Output was requested above source size (upscale)." else " Output matches source scale (not labeled as native 1080p)."
        return "Jewelry grade ($look) at ${width}x$height. $bg$scale"
    }

    private fun squareEdge(width: Int, height: Int, allowUpscale: Boolean): Int {
        val shortest = minOf(width, height).coerceAtLeast(2)
        val even = shortest - (shortest % 2)
        return if (allowUpscale) 1080 else minOf(even, 1080)
    }

    private fun effectsFor(
        look: String,
        aspectRatio: String,
        background: String,
        outputEdge: Int,
        strength: Int,
    ): List<androidx.media3.common.Effect> {
        val t = (strength.coerceIn(0, 100)) / 100f
        val contrast: Float
        val brightness: Float
        val red: Float
        val green: Float
        val blue: Float
        when (look) {
            "luxuryDark", "slowElegant" -> {
                contrast = 0.16f * t
                brightness = -0.08f * t
                red = 1f + 0.03f * t
                green = 1.00f
                blue = 1f - 0.06f * t
            }
            "premiumShowcase" -> {
                contrast = 0.10f * t
                brightness = -0.03f * t
                red = 1f + 0.06f * t
                green = 1f + 0.01f * t
                blue = 1f - 0.06f * t
            }
            "coolStudio" -> {
                contrast = 0.08f * t
                brightness = 0.00f
                red = 1f - 0.06f * t
                green = 1.00f
                blue = 1f + 0.08f * t
            }
            "highContrast" -> {
                contrast = 0.22f * t
                brightness = -0.04f * t
                red = 1.0f
                green = 1.0f
                blue = 1.0f
            }
            "ecommerceNeutral" -> {
                contrast = 0.04f * t
                brightness = 0.01f * t
                red = 1.0f
                green = 1.0f
                blue = 1.0f
            }
            "socialPortrait" -> {
                contrast = 0.12f * t
                brightness = -0.05f * t
                red = 1f + 0.04f * t
                green = 1.00f
                blue = 1f - 0.05f * t
            }
            "gemstoneCloseup" -> {
                contrast = 0.14f * t
                brightness = -0.02f * t
                red = 1f + 0.01f * t
                green = 1.00f
                blue = 1f + 0.02f * t
            }
            else -> {
                contrast = 0.04f * t
                brightness = -0.01f * t
                red = 1.0f
                green = 1.0f
                blue = 1.0f
            }
        }
        val effects = mutableListOf<androidx.media3.common.Effect>()
        if (look != "original" && strength > 0) {
            effects.add(Contrast(contrast))
            effects.add(Brightness(brightness))
            effects.add(
                RgbAdjustment.Builder()
                    .setRedScale(red)
                    .setGreenScale(green)
                    .setBlueScale(blue)
                    .build(),
            )
        }
        if (background == "darkened") {
            effects.add(
                OverlayEffect(
                    ImmutableList.of<TextureOverlay>(
                        BitmapOverlay.createStaticBitmapOverlay(vignette(outputEdge)),
                    ),
                ),
            )
        }
        val ratio = when (aspectRatio) {
            "9:16" -> 9f / 16f
            "1:1" -> 1f
            "4:5" -> 4f / 5f
            "4:3" -> 4f / 3f
            "16:9" -> 16f / 9f
            else -> 1f
        }
        val layout = Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP
        if (aspectRatio == "1:1" && outputEdge >= 2) {
            effects.add(Presentation.createForWidthAndHeight(outputEdge, outputEdge, layout))
        } else {
            effects.add(Presentation.createForAspectRatio(ratio, layout))
        }
        return effects
    }

    private fun vignette(size: Int): Bitmap {
        val edge = size.coerceAtLeast(64)
        val bitmap = Bitmap.createBitmap(edge, edge, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.shader = RadialGradient(
            edge / 2f,
            edge / 2f,
            edge * 0.62f,
            intArrayOf(Color.TRANSPARENT, Color.argb(40, 0, 0, 0), Color.argb(210, 0, 0, 0)),
            floatArrayOf(0.42f, 0.78f, 1f),
            Shader.TileMode.CLAMP,
        )
        canvas.drawRect(0f, 0f, edge.toFloat(), edge.toFloat(), paint)
        return bitmap
    }
}
