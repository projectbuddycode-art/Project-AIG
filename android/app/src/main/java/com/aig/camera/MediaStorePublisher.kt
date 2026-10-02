package com.aig.camera

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import java.io.File

object MediaStorePublisher {
    fun publish(
        context: Context?,
        sourcePath: String,
        mediaType: String,
        displayName: String,
    ): Map<String, Any>? {
        if (context == null) return null
        val source = File(sourcePath)
        if (!source.exists() || source.length() <= 0L) return null

        val isVideo = mediaType == "video"
        val mimeType = if (isVideo) "video/mp4" else "image/jpeg"
        val collection = if (isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.DATE_ADDED, System.currentTimeMillis() / 1000L)
            put(MediaStore.MediaColumns.DATE_MODIFIED, source.lastModified() / 1000L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    if (isVideo) "Movies/AIG" else "Pictures/AIG",
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val resolver = context.contentResolver
        val uri = resolver.insert(collection, values) ?: return null
        return try {
            resolver.openOutputStream(uri, "w")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("MediaStore output stream unavailable")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                resolver.update(uri, ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }, null, null)
            }

            val size = resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns.SIZE),
                null,
                null,
                null,
            )?.use { cursor ->
                if (!cursor.moveToFirst()) 0L else cursor.getLong(0)
            } ?: 0L
            if (size <= 0L) throw IllegalStateException("MediaStore item is empty")
            mapOf("uri" to uri.toString(), "size" to size)
        } catch (_: Exception) {
            resolver.delete(uri, null, null)
            null
        }
    }
}