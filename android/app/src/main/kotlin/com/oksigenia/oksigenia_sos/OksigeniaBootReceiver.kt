package com.oksigenia.oksigenia_sos

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Revive Sylvia (the background service) after a reboot ONLY when there is
 * something to monitor.
 *
 * The flutter_background_service plugin's own boot autostart is unconditional:
 * it restarts the service on every boot and immediately acquires a permanent
 * wakelock, even when the user has all monitoring turned off — draining the
 * battery for nothing (worst case: a no-WiFi mountain with no deep-Doze to
 * mask the wakelock). So the plugin's autostart is disabled (autoStartOnBoot =
 * false) and this receiver takes over: it reads the persisted state and starts
 * the service only if fall detection, inactivity, live-tracking, the Smart
 * Beacon or an in-flight alarm is active. If nothing is active, nothing starts.
 */
class OksigeniaBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON" &&
            action != "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        // Flutter's shared_preferences live in this file, keys prefixed "flutter.".
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val fall = prefs.getBoolean("flutter.fall_detection_enabled", false)
        val inactivity = prefs.getBoolean("flutter.inactivity_monitor_enabled", false)
        val liveTracking = prefs.getBoolean("flutter.live_tracking_enabled", false)
        val beacon = prefs.getBoolean("flutter.beacon_active", false)
        val alarm = prefs.getBoolean("flutter.is_alarm_active", false)

        if (!(fall || inactivity || liveTracking || beacon || alarm)) {
            // Nothing to watch → do not start the service → no wakelock in vain.
            return
        }

        try {
            val serviceIntent = Intent().apply {
                component = ComponentName(
                    context.packageName,
                    "id.flutter.flutter_background_service.BackgroundService"
                )
            }
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (_: Exception) {
            // If the service can't be started (OEM restriction, etc.) the user
            // still has the SOS once they open the app; nothing worse than today.
        }
    }
}
