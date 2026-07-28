package com.dyno.tv_notification_mirror.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class RestartAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_RESTART_SERVICE) {
            Log.d(TAG, "Watchdog alarm fired. Restarting background service...")
            try {
                val serviceIntent = Intent().apply {
                    setClassName(
                        context.packageName,
                        "id.flutter.flutter_background_service.BackgroundService"
                    )
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d(TAG, "Background service restarted via watchdog.")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to restart background service: ${e.message}")
            }
        }
    }

    companion object {
        private const val TAG = "RestartAlarmReceiver"
        const val ACTION_RESTART_SERVICE = "com.dyno.tv_notification_mirror.RESTART_SERVICE"
        const val REQUEST_CODE = 1001
        const val INTERVAL_MS = 5 * 60 * 1000L // 5 minutes
    }
}
