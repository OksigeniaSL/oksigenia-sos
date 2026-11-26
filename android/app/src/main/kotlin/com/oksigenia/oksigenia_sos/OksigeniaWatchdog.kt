package com.oksigenia.oksigenia_sos

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import androidx.core.content.ContextCompat

/**
 * Brings the monitoring service (Sylvia) back when the system killed the
 * process while something was armed.
 *
 * The plugin's own watchdog fires once, 5 s after the service starts, and is
 * never armed again: a process killed later (low memory, a manufacturer's
 * battery manager, a crash) stayed dead, with the widget still saying
 * "active", until the user opened the app.
 *
 * Inexact on purpose (minimal permissions, no exact-alarm permission): Android
 * may delay it, but it keeps running in Doze. The chain ends by itself when
 * nothing is armed; MainActivity and OksigeniaBootReceiver start it again.
 */
class OksigeniaWatchdog : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!somethingArmed(context)) return
        if (!serviceRunning(context)) {
            try {
                ContextCompat.startForegroundService(context, serviceIntent(context))
            } catch (_: Exception) {
                // Background start refused (no battery exemption): the next
                // round or opening the app will try again.
            }
        }
        schedule(context)
    }

    companion object {
        private const val INTERVAL_MS = 15 * 60 * 1000L
        private const val REQUEST_CODE = 7301
        private const val SERVICE = "id.flutter.flutter_background_service.BackgroundService"

        /** Same conditions as OksigeniaBootReceiver. */
        fun somethingArmed(context: Context): Boolean {
            // Flutter's shared_preferences live in this file, keys prefixed "flutter.".
            val p = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            return p.getBoolean("flutter.fall_detection_enabled", false) ||
                p.getBoolean("flutter.inactivity_monitor_enabled", false) ||
                p.getBoolean("flutter.live_tracking_enabled", false) ||
                p.getBoolean("flutter.beacon_active", false) ||
                p.getBoolean("flutter.is_alarm_active", false) ||
                p.getBoolean("flutter.sos_retry_active", false)
        }

        // Only our own services are listed, which is all this needs. Checked
        // first because a second startForegroundService on a running service
        // has crashed the app before (see the FGS notes in the repo history).
        @Suppress("DEPRECATION")
        fun serviceRunning(context: Context): Boolean {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            return am.getRunningServices(Int.MAX_VALUE).any { it.service.className == SERVICE }
        }

        fun serviceIntent(context: Context): Intent =
            Intent().apply { component = ComponentName(context.packageName, SERVICE) }

        fun schedule(context: Context) {
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val pi = PendingIntent.getBroadcast(
                    context, REQUEST_CODE,
                    Intent(context, OksigeniaWatchdog::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                am.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    SystemClock.elapsedRealtime() + INTERVAL_MS,
                    pi
                )
            } catch (_: Exception) {
            }
        }
    }
}
