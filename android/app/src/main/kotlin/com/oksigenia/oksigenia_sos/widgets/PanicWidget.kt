package com.oksigenia.oksigenia_sos.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.oksigenia.oksigenia_sos.R

class PanicWidget : AppWidgetProvider() {

    companion object {
        private const val ACTION_PANIC_TAP = "com.oksigenia.oksigenia_sos.widget.PANIC_TAP"
        private const val PANIC_FLAG_KEY = "flutter.widget_panic_requested"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_panic)
            val tapIntent = Intent(context, PanicWidget::class.java).apply {
                action = ACTION_PANIC_TAP
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getBroadcast(context, id, tapIntent, pendingFlags)
            // Set on every clickable layer so the launcher cannot route the tap
            // to a transparent area without a handler.
            views.setOnClickPendingIntent(R.id.panic_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.panic_button, pendingIntent)
            views.setOnClickPendingIntent(R.id.panic_text, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_PANIC_TAP) {
            // Sylvia (background_service.dart) polls this flag every 5 s in
            // _startInactivityChecker and triggers _lanzarAlarma when set.
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            prefs.edit()
                .putLong(PANIC_FLAG_KEY, System.currentTimeMillis())
                .apply()

            // If Sylvia is not running (monitoring off, app killed), wake it up
            // so the flag is read promptly. flutter_background_service binds to
            // BackgroundService; starting it as a foreground service is enough.
            try {
                val serviceIntent = Intent().apply {
                    component = ComponentName(
                        context.packageName,
                        "id.flutter.flutter_background_service.BackgroundService"
                    )
                }
                ContextCompat.startForegroundService(context, serviceIntent)
            } catch (_: Exception) {
                // If the service can't be started (battery saver, OEM kill,
                // permissions revoked) the flag remains and Sylvia will pick
                // it up on next regular cycle.
            }
        }
    }
}
