package com.dyno.tv_notification_mirror.phone

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL_METHODS = "com.dyno.tv_notification_mirror/methods"
    private val CHANNEL_EVENTS = "com.dyno.tv_notification_mirror/events"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel for checking and requesting notification listener permission
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_METHODS).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // EventChannel to stream notifications to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_EVENTS).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent != null && events != null) {
                                val action = intent.action
                                val id = intent.getStringExtra("id") ?: ""
                                val packageName = intent.getStringExtra("packageName") ?: ""
                                
                                val map = mutableMapOf<String, Any>(
                                    "id" to id,
                                    "packageName" to packageName
                                )

                                if (action == MyNotificationListener.ACTION_NEW_NOTIFICATION) {
                                    map["event"] = "notification_new"
                                    map["appName"] = intent.getStringExtra("appName") ?: ""
                                    map["title"] = intent.getStringExtra("title") ?: ""
                                    map["text"] = intent.getStringExtra("text") ?: ""
                                    map["postTime"] = intent.getLongExtra("postTime", 0L)
                                } else if (action == MyNotificationListener.ACTION_REMOVED_NOTIFICATION) {
                                    map["event"] = "notification_removed"
                                }
                                events.success(map)
                            }
                        }
                    }

                    val filter = IntentFilter().apply {
                        addAction(MyNotificationListener.ACTION_NEW_NOTIFICATION)
                        addAction(MyNotificationListener.ACTION_REMOVED_NOTIFICATION)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        registerReceiver(receiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    receiver?.let {
                        unregisterReceiver(it)
                    }
                }
            }
        )
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val cn = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        val packageName = packageName
        return cn != null && cn.contains(packageName)
    }
}
