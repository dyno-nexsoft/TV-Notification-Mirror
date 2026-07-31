package com.dyno.tv_notification_mirror.tv

import android.app.AlarmManager
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build

class TvApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        scheduleWatchdogAlarm()
        registerOverlayReceiver()
    }

    /// Registers the overlay receiver on the application context so it survives
    /// the Activity lifecycle. This lets the background service keep showing
    /// notification overlays even after the TV app is swiped away from recents
    /// (which destroys MainActivity and its Flutter UI isolate).
    private fun registerOverlayReceiver() {
        val filter = IntentFilter().apply {
            addAction(OverlayManager.ACTION_SHOW_OVERLAY)
            addAction(OverlayManager.ACTION_HIDE_OVERLAY)
            addAction(OverlayManager.ACTION_SHOW_STATUS_OVERLAY)
            addAction(OverlayManager.ACTION_HIDE_STATUS_OVERLAY)
            addAction(OverlayManager.ACTION_UPDATE_STATUS_OVERLAY)
        }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent == null) return
                when (intent.action) {
                    OverlayManager.ACTION_SHOW_OVERLAY -> OverlayManager.show(
                        context = this@TvApplication,
                        title = intent.getStringExtra("title") ?: "",
                        text = intent.getStringExtra("text") ?: "",
                        appName = intent.getStringExtra("appName") ?: "",
                        base64Icon = intent.getStringExtra("base64Icon"),
                        overlayPosition = intent.getStringExtra("overlayPosition"),
                        duration = intent.getIntExtra("duration", 5000),
                        category = intent.getStringExtra("category") ?: "generic",
                        opacity = intent.getDoubleExtra("overlayOpacity", 0.95),
                        alertSoundUri = intent.getStringExtra("alertSoundUri"),
                    )
                    OverlayManager.ACTION_HIDE_OVERLAY -> OverlayManager.hide()
                    OverlayManager.ACTION_SHOW_STATUS_OVERLAY -> OverlayManager.showStatusOverlay(this@TvApplication)
                    OverlayManager.ACTION_HIDE_STATUS_OVERLAY -> OverlayManager.hideStatusOverlay()
                    OverlayManager.ACTION_UPDATE_STATUS_OVERLAY -> OverlayManager.updateStatusOverlay(
                        intent.getStringExtra("text") ?: ""
                    )
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
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
