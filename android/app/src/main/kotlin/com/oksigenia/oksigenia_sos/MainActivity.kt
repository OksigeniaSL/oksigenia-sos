package com.oksigenia.oksigenia_sos

import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.oksigenia.sos/sms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phone = call.argument<String>("phone")
                    val msg = call.argument<String>("msg")
                    sendSMS(phone, msg, result)
                }
                "wakeScreen" -> {
                    wakeUpScreen()
                    result.success("OK")
                }
                "sleepScreen" -> {
                    allowScreenSleep()
                    result.success("OK")
                }
                else -> result.notImplemented()
            }
        }
    }

    // FUERZA ENCENDER PANTALLA (Para la Alarma Roja)
    private fun wakeUpScreen() {
        activity.runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    // PERMITE APAGAR PANTALLA (Para Ahorrar Batería tras el envío)
    private fun allowScreenSleep() {
        activity.runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(false)
                setTurnScreenOn(false)
            }
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    private fun sendSMS(phone: String?, msg: String?, result: MethodChannel.Result) {
        try {
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(SmsManager::class.java)
            } else {
                SmsManager.getDefault()
            }
            
            val parts = smsManager.divideMessage(msg)
            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            
            result.success("OK")
        } catch (e: Exception) {
            result.error("SMS_ERROR", e.message, null)
        }
    }
}
