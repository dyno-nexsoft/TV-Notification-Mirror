package com.dyno.tv_notification_mirror.phone

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import android.os.Build
import android.util.Log

class MyNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "MyNotificationListener"
        const val ACTION_NEW_NOTIFICATION = "com.dyno.tv_notification_mirror.NEW_NOTIFICATION"
        const val ACTION_REMOVED_NOTIFICATION = "com.dyno.tv_notification_mirror.REMOVED_NOTIFICATION"

        /// Best-effort classification for the TV overlay: Android does not expose a
        /// distinct "video call" category, so we heuristically upgrade a CATEGORY_CALL
        /// notification to "video_call" when its text mentions video.
        private fun classifyCategory(category: String?, title: String, text: String): String {
            return when (category) {
                Notification.CATEGORY_CALL -> {
                    val mentionsVideo = title.contains("video", ignoreCase = true) ||
                        text.contains("video", ignoreCase = true)
                    if (mentionsVideo) "video_call" else "voice_call"
                }
                Notification.CATEGORY_MESSAGE -> "message"
                else -> "generic"
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        // Skip our own app's notifications to prevent loops
        if (packageName == this.packageName) {
            return
        }

        // If the process was restarted by the system just to deliver this
        // notification, the Flutter background isolate (which owns the
        // broadcast receiver + WebSocket connection) is not running yet.
        // Start it so this and subsequent notifications reach the TV, instead
        // of waiting for the watchdog alarm to fire.
        ensureBackgroundServiceRunning()

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val id = sbn.id.toString()
        val postTime = sbn.postTime

        val appName = try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }

        val category = classifyCategory(sbn.notification.category, title, text)

        Log.d(TAG, "Notification posted from $packageName ($appName): $title - $text [$category]")

        val intent = Intent(ACTION_NEW_NOTIFICATION).apply {
            setPackage(this@MyNotificationListener.packageName)
            putExtra("id", id)
            putExtra("packageName", packageName)
            putExtra("appName", appName)
            putExtra("title", title)
            putExtra("text", text)
            putExtra("postTime", postTime)
            putExtra("category", category)
        }
        sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (packageName == this.packageName) {
            return
        }

        val id = sbn.id.toString()
        Log.d(TAG, "Notification removed: $id from $packageName")

        val intent = Intent(ACTION_REMOVED_NOTIFICATION).apply {
            setPackage(this@MyNotificationListener.packageName)
            putExtra("id", id)
            putExtra("packageName", packageName)
        }
        sendBroadcast(intent)
    }

    /// Starts `flutter_background_service`'s foreground service if it isn't
    /// already running. This is what boots the background isolate that holds
    /// the notification broadcast receiver and the WebSocket connection to the
    /// TV. Starting it here (from the system-bound listener callback) closes
    /// the gap where a freshly-restarted process would otherwise drop the
    /// broadcast until the watchdog alarm fires.
    private fun ensureBackgroundServiceRunning() {
        try {
            val intent = Intent(this, id.flutter.flutter_background_service.BackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start background service: ${e.message}")
        }
    }
}
