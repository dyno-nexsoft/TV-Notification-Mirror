package com.example.native_bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class NativeBridgePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var receiver: BroadcastReceiver? = null

    companion object {
        const val ACTION_NEW_NOTIFICATION = "com.dyno.tv_notification_mirror.NEW_NOTIFICATION"
        const val ACTION_REMOVED_NOTIFICATION = "com.dyno.tv_notification_mirror.REMOVED_NOTIFICATION"
        const val ACTION_SHOW_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_OVERLAY"
        const val ACTION_HIDE_OVERLAY = "com.dyno.tv_notification_mirror.HIDE_OVERLAY"
        const val ACTION_SHOW_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_STATUS_OVERLAY"
        const val ACTION_HIDE_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.HIDE_STATUS_OVERLAY"
        const val ACTION_UPDATE_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.UPDATE_STATUS_OVERLAY"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, "com.dyno.tv_notification_mirror/methods")
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, "com.dyno.tv_notification_mirror/events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "checkPermission") {
            result.success(isNotificationListenerEnabled())
        } else if (call.method == "openSettings") {
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context?.startActivity(intent)
            result.success(true)
        } else if (call.method == "broadcastShowOverlay") {
            // Sent from the background isolate so the TV overlay keeps working
            // even after the UI Activity (and its MethodChannel handler) is gone.
            val intent = Intent(ACTION_SHOW_OVERLAY).apply {
                setPackage(context?.packageName)
                putExtra("title", call.argument<String>("title") ?: "")
                putExtra("text", call.argument<String>("text") ?: "")
                putExtra("appName", call.argument<String>("appName") ?: "")
                putExtra("base64Icon", call.argument<String>("base64Icon"))
                putExtra("overlayPosition", call.argument<String>("overlayPosition"))
                putExtra("duration", call.argument<Int>("duration") ?: 5000)
                putExtra("category", call.argument<String>("category") ?: "generic")
                putExtra("overlayOpacity", call.argument<Double>("overlayOpacity") ?: 0.95)
                putExtra("alertSoundUri", call.argument<String>("alertSoundUri"))
            }
            context?.sendBroadcast(intent)
            result.success(true)
        } else if (call.method == "broadcastHideOverlay") {
            val intent = Intent(ACTION_HIDE_OVERLAY).apply {
                setPackage(context?.packageName)
            }
            context?.sendBroadcast(intent)
            result.success(true)
        } else if (call.method == "broadcastShowStatusOverlay") {
            val intent = Intent(ACTION_SHOW_STATUS_OVERLAY).apply {
                setPackage(context?.packageName)
            }
            context?.sendBroadcast(intent)
            result.success(true)
        } else if (call.method == "broadcastHideStatusOverlay") {
            val intent = Intent(ACTION_HIDE_STATUS_OVERLAY).apply {
                setPackage(context?.packageName)
            }
            context?.sendBroadcast(intent)
            result.success(true)
        } else if (call.method == "broadcastUpdateStatusOverlay") {
            val intent = Intent(ACTION_UPDATE_STATUS_OVERLAY).apply {
                setPackage(context?.packageName)
                putExtra("text", call.argument<String>("text") ?: "")
            }
            context?.sendBroadcast(intent)
            result.success(true)
        } else if (call.method == "isIgnoringBatteryOptimizations") {
            result.success(isIgnoringBatteryOptimizations())
        } else if (call.method == "requestIgnoreBatteryOptimizations") {
            requestIgnoreBatteryOptimizations()
            result.success(true)
        } else if (call.method == "openBatteryOptimizationSettings") {
            openBatteryOptimizationSettings()
            result.success(true)
        } else {
            result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val currentContext = context ?: return
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (intent != null && events != null) {
                    val action = intent.action
                    val id = intent.getStringExtra("id") ?: ""
                    val packageName = intent.getStringExtra("packageName") ?: ""
                    
                    val map = mutableMapOf<String, Any>(
                        "id" to id,
                        "packageName" to packageName
                    )

                    if (action == ACTION_NEW_NOTIFICATION) {
                        map["event"] = "notification_new"
                        map["appName"] = intent.getStringExtra("appName") ?: ""
                        map["title"] = intent.getStringExtra("title") ?: ""
                        map["text"] = intent.getStringExtra("text") ?: ""
                        map["postTime"] = intent.getLongExtra("postTime", 0L)
                        map["category"] = intent.getStringExtra("category") ?: "generic"
                    } else if (action == ACTION_REMOVED_NOTIFICATION) {
                        map["event"] = "notification_removed"
                    }
                    events.success(map)
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(ACTION_NEW_NOTIFICATION)
            addAction(ACTION_REMOVED_NOTIFICATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            currentContext.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            currentContext.registerReceiver(receiver, filter)
        }
    }

    override fun onCancel(arguments: Any?) {
        receiver?.let {
            context?.unregisterReceiver(it)
        }
        receiver = null
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val currentContext = context ?: return false
        val cn = Settings.Secure.getString(currentContext.contentResolver, "enabled_notification_listeners")
        val packageName = "com.dyno.tv_notification_mirror.phone"
        return cn != null && cn.contains(packageName)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val currentContext = context ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = currentContext.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(currentContext.packageName)
    }

    /// Opens the system dialog asking the user to exempt this app from battery
    /// optimization (Doze). Falls back to the app list if the direct request
    /// isn't available. This is the stock-Android whitelist; OEM ROMs
    /// (MIUI, ColorOS, EMUI...) layer extra autostart settings on top that
    /// still need manual user configuration.
    private fun requestIgnoreBatteryOptimizations() {
        val currentContext = context ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !isIgnoringBatteryOptimizations()) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${currentContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                currentContext.startActivity(intent)
                return
            } catch (_: Exception) {
                // Fall through to the generic list.
            }
        }
        openBatteryOptimizationSettings()
    }

    private fun openBatteryOptimizationSettings() {
        val currentContext = context ?: return
        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            currentContext.startActivity(intent)
        } catch (_: Exception) {
            // No battery-optimization screen available; nothing else to do.
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }
}
