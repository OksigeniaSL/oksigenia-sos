package com.oksigenia.oksigenia_sos

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // Solo mantenemos el canal para despertar la pantalla, el SMS va por plugin
    private val CHANNEL = "com.oksigenia.sos/sms"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Los canales reales ('my_foreground', 'oksigenia_alarm') los crea el
        // lado Dart. El canal 'oksigenia_sos_modular_v1' que se creaba aquí
        // quedó huérfano: nada publicaba en él, pero aparecía en los ajustes
        // del sistema y silenciarlo daba falsa sensación de control sobre el
        // servicio. Se borra para retirarlo de instalaciones existentes.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.deleteNotificationChannel("oksigenia_sos_modular_v1")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // "sendSMS" ELIMINADO: Lo maneja background_sms
                "bringToFront" -> {
                    wakeUpScreen()
                    val intent = Intent(this, MainActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    startActivity(intent)
                    result.success("OK")
                }
                "wakeScreen" -> {
                    wakeUpScreen()
                    result.success("OK")
                }
                "sleepScreen" -> {
                    allowScreenSleep()
                    result.success("OK")
                }
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        result.success(nm.canUseFullScreenIntent())
                    } else {
                        result.success(true)
                    }
                }
                "requestFullScreenIntentPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success("OK")
                }
                "getSimCountryIso" -> {
                    val country = try {
                        resources.configuration.locales[0].country.uppercase().trim()
                    } catch (_: Exception) { "" }
                    result.success(country)
                }
                "isSmsPermissionGranted" -> {
                    val granted = checkSelfPermission(android.Manifest.permission.SEND_SMS) ==
                        android.content.pm.PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun wakeUpScreen() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    private fun allowScreenSleep() {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(false)
                setTurnScreenOn(false)
            }
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }
}