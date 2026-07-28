package com.dyno.tv_notification_mirror.tv

import android.app.AlarmManager
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class TvApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        scheduleWatchdogAlarm()
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

    private fun scheduleWatchdogAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val intent = Intent(this, RestartAlarmReceiver::class.java).apply {
            action = RestartAlarmReceiver.ACTION_RESTART_SERVICE
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, RestartAlarmReceiver.REQUEST_CODE, intent, flags
        )

        alarmManager.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            RestartAlarmReceiver.INTERVAL_MS,
            RestartAlarmReceiver.INTERVAL_MS,
            pendingIntent
        )
    }
}
