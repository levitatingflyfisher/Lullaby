package com.openhearth.lullaby

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

class LullabyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        prefs: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.lullaby_widget)

        // Baby name
        val babyName = prefs.getString("lullaby.baby_name", "–") ?: "–"
        views.setTextViewText(R.id.tv_baby_name, babyName)

        // Recency rows
        val feedAgo = prefs.getString("lullaby.last_feed_ago", "–") ?: "–"
        val sleepAgo = prefs.getString("lullaby.last_sleep_ago", "–") ?: "–"
        val diaperAgo = prefs.getString("lullaby.last_diaper_ago", "–") ?: "–"
        views.setTextViewText(R.id.tv_last_feed, "🍼 Fed   $feedAgo")
        views.setTextViewText(R.id.tv_last_sleep, "😴 Nap   $sleepAgo")
        views.setTextViewText(R.id.tv_last_diaper, "💧 Changed   $diaperAgo")

        // Timer row
        val timerStartStr = prefs.getString("lullaby.active_timer_start", null)
        val timerType = prefs.getString("lullaby.active_timer_type", null)
        if (timerStartStr != null && timerType != null) {
            try {
                val startMs = parseIso8601(timerStartStr)
                val elapsedMs = System.currentTimeMillis() - startMs
                val chronometerBase = SystemClock.elapsedRealtime() - elapsedMs
                val label = if (timerType == "feeding") "🍼" else "😴"
                views.setChronometer(
                    R.id.timer_chronometer,
                    chronometerBase,
                    "$label %s",
                    true
                )
                views.setViewVisibility(R.id.timer_chronometer, View.VISIBLE)
            } catch (e: Exception) {
                views.setViewVisibility(R.id.timer_chronometer, View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.timer_chronometer, View.GONE)
        }

        // Tap to open dashboard via deep link
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("lullaby://dashboard"))
        val flags = if (Build.VERSION.SDK_INT >= 23) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun parseIso8601(iso: String): Long {
        return if (Build.VERSION.SDK_INT >= 26) {
            java.time.Instant.parse(iso).toEpochMilli()
        } else {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            sdf.timeZone = TimeZone.getTimeZone("UTC")
            try {
                sdf.parse(iso)?.time ?: throw IllegalArgumentException("Unparseable: $iso")
            } catch (e: Exception) {
                // Try without milliseconds
                val sdf2 = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
                sdf2.timeZone = TimeZone.getTimeZone("UTC")
                sdf2.parse(iso)?.time ?: throw IllegalArgumentException("Unparseable: $iso")
            }
        }
    }
}
