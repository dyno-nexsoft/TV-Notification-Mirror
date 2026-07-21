package com.dyno.tv_notification_mirror.tv

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class TvApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        // Create the notification channel BEFORE any component (Activity, Service,
        // BroadcastReceiver) starts. This is the earliest possible hook in the
        // Android process lifecycle, ensuring the channel always exists when
        // flutter_background_service calls startForeground().
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "tv_mirror_service_channel",
                "TV Mirror Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the WebSocket server running in the background"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }
}
