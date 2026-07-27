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

            // `shared_preferences` (Flutter plugin) stores values in this prefs
            // file, keys prefixed with "flutter.". Read directly since the
            // Flutter engine/ProviderScope isn't up yet at boot time. Missing
            // key defaults to true, preserving the previous always-on behavior.
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val launchOnBoot = prefs.getBoolean("flutter.tv_launch_on_boot", true)
            if (!launchOnBoot) {
                Log.d("BootReceiver", "Launch on Boot disabled by user, skipping.")
                return
            }

            Log.d("BootReceiver", "TV booted, starting background service...")

            try {
                // Start flutter_background_service's native service component
                val serviceIntent = Intent().apply {
                    setClassName(context.packageName, "id.flutter.flutter_background_service.BackgroundService")
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
