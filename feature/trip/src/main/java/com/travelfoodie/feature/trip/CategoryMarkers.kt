package com.travelfoodie.feature.trip

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import com.google.android.gms.maps.model.BitmapDescriptor
import com.google.android.gms.maps.model.BitmapDescriptorFactory

/** Emoji and colour shown on the map for one restaurant category. */
internal data class CategoryStyle(val emoji: String, val color: Int)

/**
 * Maps a restaurant category (the same labels as the restaurant filter chips) to its map
 * style. Matching is by substring so labels such as "카페/디저트" still resolve.
 * Anything unrecognised gets the neutral plate icon.
 */
internal fun categoryStyleFor(category: String): CategoryStyle = when {
    category.contains("한식") -> CategoryStyle("🍚", 0xFFE57373.toInt())
    category.contains("일식") -> CategoryStyle("🍣", 0xFFF06292.toInt())
    category.contains("중식") -> CategoryStyle("🥟", 0xFFFFB74D.toInt())
    category.contains("양식") -> CategoryStyle("🍝", 0xFF81C784.toInt())
    category.contains("카페") -> CategoryStyle("☕", 0xFF8D6E63.toInt())
    category.contains("디저트") -> CategoryStyle("🍰", 0xFFBA68C8.toInt())
    category.contains("해산물") -> CategoryStyle("🦐", 0xFF4FC3F7.toInt())
    else -> CategoryStyle("🍽️", 0xFF90A4AE.toInt())
}

/**
 * Draws round, colour-coded map markers with a food emoji, so no image assets are needed.
 * Icons are cached per style. Call only after the map is ready (the Maps SDK must be
 * initialised before a BitmapDescriptor can be created).
 */
internal object CategoryMarkers {

    private const val SIZE_DP = 40f
    private const val STROKE_DP = 3f

    private val cache = HashMap<CategoryStyle, BitmapDescriptor>()

    fun iconFor(context: Context, category: String): BitmapDescriptor {
        val style = categoryStyleFor(category)
        return cache.getOrPut(style) { draw(context, style) }
    }

    private fun draw(context: Context, style: CategoryStyle): BitmapDescriptor {
        val density = context.resources.displayMetrics.density
        val sizePx = (SIZE_DP * density).toInt()
        val ringPx = STROKE_DP * density
        val radius = sizePx / 2f
        // Copied into plain locals: inside Paint.apply { } the names `style` and `strokeWidth`
        // would resolve to the Paint's own properties instead of our values.
        val fillColor = style.color
        val emoji = style.emoji

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        fillPaint.color = fillColor

        val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        ringPaint.color = Color.WHITE
        ringPaint.style = Paint.Style.STROKE
        ringPaint.strokeWidth = ringPx

        val circleRadius = radius - ringPx / 2f
        canvas.drawCircle(radius, radius, circleRadius, fillPaint)
        canvas.drawCircle(radius, radius, circleRadius, ringPaint)

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        textPaint.textSize = sizePx * 0.5f
        textPaint.textAlign = Paint.Align.CENTER
        val baseline = radius - (textPaint.descent() + textPaint.ascent()) / 2f
        canvas.drawText(emoji, radius, baseline, textPaint)

        return BitmapDescriptorFactory.fromBitmap(bitmap)
    }
}
