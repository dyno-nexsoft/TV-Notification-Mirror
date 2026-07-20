package com.dyno.tv_notification_mirror.phone

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import android.util.Log

class MyNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "MyNotificationListener"
        const val ACTION_NEW_NOTIFICATION = "com.dyno.tv_notification_mirror.NEW_NOTIFICATION"
        const val ACTION_REMOVED_NOTIFICATION = "com.dyno.tv_notification_mirror.REMOVED_NOTIFICATION"
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        
        // Skip our own app's notifications to prevent loops
        if (packageName == this.packageName) {
            return
        }

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val id = sbn.id.toString()
        val postTime = sbn.postTime

        Log.d(TAG, "Notification posted from $packageName: $title - $text")

        val intent = Intent(ACTION_NEW_NOTIFICATION).apply {
            setPackage(this@MyNotificationListener.packageName)
            putExtra("id", id)
            putExtra("packageName", packageName)
            putExtra("title", title)
            putExtra("text", text)
            putExtra("postTime", postTime)
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
}
