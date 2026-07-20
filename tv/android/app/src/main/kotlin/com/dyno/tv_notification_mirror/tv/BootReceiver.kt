package com.dyno.tv_notification_mirror.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootReceiver", "TV booted, starting background service...")
            
            try {
                // Start flutter_background_service's native service component
                val serviceIntent = Intent().apply {
                    setClassName(context.packageName, "com.pravera.flutter_background_service.BackgroundService")
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.d("BootReceiver", "Background service started successfully.")
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to start background service: ${e.message}")
            }
        }
    }
}
