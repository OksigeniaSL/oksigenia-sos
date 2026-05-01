package com.oksigenia.oksigenia_sos.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.os.Build
import android.widget.RemoteViews
import com.oksigenia.oksigenia_sos.MainActivity
import com.oksigenia.oksigenia_sos.R

class StatusWidget : AppWidgetProvider() {

    companion object {
        private const val ACTION_TICK = "com.oksigenia.oksigenia_sos.widget.STATUS_TICK"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        // Flutter's shared_preferences plugin prefixes string keys with "flutter.".
        private const val KEY_FALL = "flutter.fall_detection_enabled"
        private const val KEY_INACTIVITY = "flutter.inactivity_monitor_enabled"
        private const val KEY_LIVE_TRACKING = "flutter.live_tracking_enabled"
        private const val KEY_ALARM_ACTIVE = "flutter.is_alarm_active"
        private const val KEY_SENTINEL_STATE = "flutter.widget_sentinel_state"
        private const val KEY_PROFILE = "flutter.activity_profile"
        private const val KEY_INACTIVITY_LIMIT = "flutter.inactivity_time"
        private const val TICK_INTERVAL_MS = 60_000L
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id -> renderWidget(context, appWidgetManager, id) }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleTick(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelTick(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TICK) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, StatusWidget::class.java))
            ids.forEach { id -> renderWidget(context, manager, id) }
            scheduleTick(context)
        }
    }

    private fun renderWidget(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_status)
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)

        val fallActive = prefs.getBoolean(KEY_FALL, false)
        val inactivityActive = prefs.getBoolean(KEY_INACTIVITY, false)
        val liveTrackingActive = prefs.getBoolean(KEY_LIVE_TRACKING, false)
        val monitoringActive = fallActive || inactivityActive
        val alarmActive = prefs.getBoolean(KEY_ALARM_ACTIVE, false)
        val sentinelState = prefs.getString(KEY_SENTINEL_STATE, "green") ?: "green"
        val profileName = prefs.getString(KEY_PROFILE, "trekking") ?: "trekking"
        // Flutter shared_preferences stores Dart int as Long on Android.
        val inactivityLimitSec = try {
            prefs.getLong(KEY_INACTIVITY_LIMIT, 3600L).toInt()
        } catch (_: ClassCastException) {
            prefs.getInt(KEY_INACTIVITY_LIMIT, 3600)
        }

        // Profile name: capitalize first letter, replace camel keys
        val profileLabel = humanProfile(profileName)
        views.setTextViewText(R.id.status_profile, profileLabel)

        // Sentinel state text + dot color
        val statusText = when {
            !monitoringActive -> context.getString(R.string.widget_status_off)
            alarmActive -> context.getString(R.string.widget_status_alarm)
            sentinelState == "yellow" -> context.getString(R.string.widget_status_yellow)
            sentinelState == "orange" -> context.getString(R.string.widget_status_orange)
            else -> context.getString(R.string.widget_status_active)
        }
        val dotColor = when {
            !monitoringActive -> 0xFF607D8B.toInt()
            alarmActive || sentinelState == "red" -> 0xFFD32F2F.toInt()
            sentinelState == "orange" -> 0xFFFF6F00.toInt()
            sentinelState == "yellow" -> 0xFFFBC02D.toInt()
            else -> 0xFF388E3C.toInt()
        }
        views.setInt(R.id.status_dot, "setColorFilter", dotColor)
        views.setTextViewText(R.id.status_text, statusText)

        // Active modes line: "Caídas · Inactividad 1h · Tracking"
        val parts = mutableListOf<String>()
        if (fallActive) parts.add(context.getString(R.string.widget_mode_fall))
        if (inactivityActive) {
            parts.add(
                context.getString(R.string.widget_mode_inactivity_fmt, formatDuration(inactivityLimitSec))
            )
        }
        if (liveTrackingActive) parts.add(context.getString(R.string.widget_mode_tracking))
        val modesText = if (parts.isEmpty())
            context.getString(R.string.widget_modes_none)
        else
            parts.joinToString(" · ")
        views.setTextViewText(R.id.status_modes, modesText)

        // Battery
        val battery = readBattery(context)
        val batteryText = if (battery >= 0) "🔋 $battery%" else "🔋 —"
        views.setTextViewText(R.id.status_battery, batteryText)

        // Tap → open app
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, id, openAppIntent, pendingFlags)
        views.setOnClickPendingIntent(R.id.status_root, pendingIntent)

        manager.updateAppWidget(id, views)
    }

    private fun humanProfile(raw: String): String = when (raw) {
        "trekking" -> "🥾 Trekking"
        "trailMtb" -> "🚵 Trail/MTB"
        "mountaineering" -> "🧗 Alpinismo"
        "paragliding" -> "🪂 Parapente"
        "kayak" -> "🛶 Kayak"
        "equitation" -> "🐴 Equitación"
        "professional" -> "👷 Profesional"
        else -> raw.replaceFirstChar { it.uppercase() }
    }

    private fun formatDuration(seconds: Int): String {
        if (seconds <= 0) return "—"
        val minutes = seconds / 60
        return when {
            minutes < 60 -> "${minutes}m"
            minutes % 60 == 0 -> "${minutes / 60}h"
            else -> "${minutes / 60}h${minutes % 60}m"
        }
    }

    private fun readBattery(context: Context): Int = try {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    } catch (_: Exception) { -1 }

    private fun tickPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, StatusWidget::class.java).apply { action = ACTION_TICK }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    private fun scheduleTick(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.set(
            AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + TICK_INTERVAL_MS,
            tickPendingIntent(context)
        )
    }

    private fun cancelTick(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(tickPendingIntent(context))
    }
}
