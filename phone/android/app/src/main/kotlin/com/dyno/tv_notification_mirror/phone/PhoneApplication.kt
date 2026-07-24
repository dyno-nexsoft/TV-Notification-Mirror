package com.dyno.tv_notification_mirror.phone

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.app.FlutterApplication

class PhoneApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "phone_mirror_service_channel",
                "Phone Mirror Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the app running in the background to send notifications to TV"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }
}
