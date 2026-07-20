package com.dyno.tv_notification_mirror.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivityTV"
        private const val CHANNEL = "com.dyno.tv_notification_mirror/overlay"
        const val ACTION_SHOW_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_OVERLAY"
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var removeRunnable: Runnable? = null
    private var overlayReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Register local broadcast receiver to show overlay from background service
        overlayReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent != null && intent.action == ACTION_SHOW_OVERLAY) {
                    val title = intent.getStringExtra("title") ?: ""
                    val text = intent.getStringExtra("text") ?: ""
                    val appName = intent.getStringExtra("appName") ?: ""
                    val duration = intent.getIntExtra("duration", 5000)
                    
                    showNotificationOverlay(title, text, appName, duration)
                }
            }
        }
        val filter = IntentFilter(ACTION_SHOW_OVERLAY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(overlayReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(overlayReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        overlayReceiver?.let {
            unregisterReceiver(it)
        }
        hideNotificationOverlay()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "showOverlay" -> {
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    val appName = call.argument<String>("appName") ?: ""
                    val duration = call.argument<Int>("duration") ?: 5000
                    
                    showNotificationOverlay(title, text, appName, duration)
                    result.success(true)
                }
                "hideOverlay" -> {
                    hideNotificationOverlay()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open overlay permission settings: ${e.message}")
            }
        }
    }

    private fun showNotificationOverlay(title: String, text: String, appName: String, duration: Int) {
        handler.post {
            hideNotificationOverlay()

            if (!hasOverlayPermission()) {
                Log.w(TAG, "Overlay permission not granted. Cannot show overlay.")
                return@post
            }

            try {
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
                
                overlayView = inflater.inflate(R.layout.notification_overlay_layout, null)
                
                overlayView?.findViewById<TextView>(R.id.appNameText)?.text = appName
                overlayView?.findViewById<TextView>(R.id.titleText)?.text = title
                overlayView?.findViewById<TextView>(R.id.bodyText)?.text = text

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
                    else 
                        WindowManager.LayoutParams.TYPE_SYSTEM_ALERT,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                )

                layoutParams.gravity = Gravity.TOP or Gravity.END
                layoutParams.x = 80
                layoutParams.y = 80

                windowManager?.addView(overlayView, layoutParams)
                Log.d(TAG, "Overlay displayed: $title")

                removeRunnable = Runnable {
                    hideNotificationOverlay()
                }
                handler.postDelayed(removeRunnable!!, duration.toLong())
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay view: ${e.message}")
            }
        }
    }

    private fun hideNotificationOverlay() {
        if (overlayView != null && windowManager != null) {
            try {
                windowManager?.removeView(overlayView)
                Log.d(TAG, "Overlay removed.")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to remove overlay view: ${e.message}")
            } finally {
                overlayView = null
                removeRunnable?.let { handler.removeCallbacks(it) }
                removeRunnable = null
            }
        }
    }
}
