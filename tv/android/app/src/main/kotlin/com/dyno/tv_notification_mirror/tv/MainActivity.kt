package com.dyno.tv_notification_mirror.tv

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.graphics.BitmapFactory
import android.util.Base64
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivityTV"
        private const val CHANNEL = "com.dyno.tv_notification_mirror/overlay"
        private const val REQUEST_PICK_ALERT_SOUND = 4201
        const val ACTION_SHOW_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_OVERLAY"
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var removeRunnable: Runnable? = null
    private var overlayReceiver: BroadcastReceiver? = null
    private var pendingAlertSoundResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create notification channel FIRST — before flutter_background_service
        // calls startForeground(), which requires this channel to already exist.
        // Without this, removing `await initializeBackgroundService()` in Dart
        // can cause a race condition → CannotPostForegroundServiceNotificationException.
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

        // Register local broadcast receiver to show overlay from background service
        overlayReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent != null && intent.action == ACTION_SHOW_OVERLAY) {
                    val title = intent.getStringExtra("title") ?: ""
                    val text = intent.getStringExtra("text") ?: ""
                    val appName = intent.getStringExtra("appName") ?: ""
                    val base64Icon = intent.getStringExtra("base64Icon")
                    val overlayPosition = intent.getStringExtra("overlayPosition")
                    val duration = intent.getIntExtra("duration", 5000)
                    val category = intent.getStringExtra("category") ?: "generic"
                    val opacity = intent.getDoubleExtra("overlayOpacity", 0.95)
                    val alertSoundUri = intent.getStringExtra("alertSoundUri")

                    showNotificationOverlay(
                        title, text, appName, base64Icon, overlayPosition, duration,
                        category, opacity, alertSoundUri
                    )
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
                "checkNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "showOverlay" -> {
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    val appName = call.argument<String>("appName") ?: ""
                    val base64Icon = call.argument<String>("base64Icon")
                    val overlayPosition = call.argument<String>("overlayPosition")
                    val duration = call.argument<Int>("duration") ?: 5000
                    val category = call.argument<String>("category") ?: "generic"
                    val opacity = call.argument<Double>("overlayOpacity") ?: 0.95
                    val alertSoundUri = call.argument<String>("alertSoundUri")

                    showNotificationOverlay(
                        title, text, appName, base64Icon, overlayPosition, duration,
                        category, opacity, alertSoundUri
                    )
                    result.success(true)
                }
                "hideOverlay" -> {
                    hideNotificationOverlay()
                    result.success(true)
                }
                "pickAlertSound" -> {
                    pickAlertSound(result)
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

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 102)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to request notification permission: ${e.message}")
            }
        }
    }

    /// Opens the system ringtone picker (includes a built-in "Silent" entry).
    /// The result comes back asynchronously via onActivityResult, so we stash
    /// the pending MethodChannel.Result until then.
    private fun pickAlertSound(result: MethodChannel.Result) {
        pendingAlertSoundResult = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                RingtoneManager.getActualDefaultRingtoneUri(this@MainActivity, RingtoneManager.TYPE_NOTIFICATION)
            )
        }
        try {
            startActivityForResult(intent, REQUEST_PICK_ALERT_SOUND)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open ringtone picker: ${e.message}")
            pendingAlertSoundResult = null
            result.success(null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_ALERT_SOUND) return

        val pending = pendingAlertSoundResult
        pendingAlertSoundResult = null

        // RESULT_CANCELED means the user backed out without choosing anything
        // (including e.g. no ringtone-picker app being available) — leave the
        // setting unchanged rather than treating it as an explicit "Silent" pick.
        if (resultCode != RESULT_OK) {
            pending?.success(null)
            return
        }
        val uri = data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        pending?.success(uri?.toString() ?: "silent")
    }

    private fun playAlertSound(alertSoundUri: String?) {
        if (alertSoundUri == "silent") return
        try {
            val uri = if (alertSoundUri != null) {
                Uri.parse(alertSoundUri)
            } else {
                RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_NOTIFICATION)
            }
            RingtoneManager.getRingtone(this, uri)?.play()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alert sound: ${e.message}")
        }
    }

    /// Builds the overlay's rounded background at runtime so [opacity] (0..1)
    /// is adjustable — replaces the old static `overlay_background` drawable.
    private fun buildOverlayBackground(opacity: Double): GradientDrawable {
        val alpha = (opacity.coerceIn(0.0, 1.0) * 255).toInt()
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 16f * resources.displayMetrics.density
            setColor(android.graphics.Color.argb(alpha, 0x20, 0x21, 0x24))
            setStroke((1f * resources.displayMetrics.density).toInt(), 0x1AFFFFFF)
        }
    }

    private fun showNotificationOverlay(
        title: String,
        text: String,
        appName: String,
        base64Icon: String?,
        overlayPosition: String?,
        duration: Int,
        category: String,
        opacity: Double,
        alertSoundUri: String?
    ) {
        handler.post {
            hideNotificationOverlay()

            if (!hasOverlayPermission()) {
                Log.w(TAG, "Overlay permission not granted. Cannot show overlay.")
                return@post
            }

            try {
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater

                val view = inflater.inflate(R.layout.notification_overlay_layout, null)
                overlayView = view

                view.findViewById<View>(R.id.overlayRoot)?.background = buildOverlayBackground(opacity)
                view.findViewById<TextView>(R.id.titleText)?.text = title
                view.findViewById<TextView>(R.id.bodyText)?.text = text
                view.findViewById<TextView>(R.id.timeText)?.text = "Just now"

                val isCall = category == "voice_call" || category == "video_call"
                val isMessage = category == "message"

                val appNameText = view.findViewById<TextView>(R.id.appNameText)
                val timeGroup = view.findViewById<View>(R.id.timeGroup)
                when (category) {
                    "voice_call" -> {
                        appNameText?.text = "INCOMING CALL"
                        timeGroup?.visibility = View.GONE
                    }
                    "video_call" -> {
                        appNameText?.text = "INCOMING VIDEO CALL"
                        timeGroup?.visibility = View.GONE
                    }
                    else -> {
                        appNameText?.text = appName
                        timeGroup?.visibility = View.VISIBLE
                    }
                }

                val fallbackGlyph = view.findViewById<ImageView>(R.id.fallbackGlyph)
                fallbackGlyph?.setImageResource(
                    if (isCall || isMessage) R.drawable.ic_person_placeholder
                    else R.drawable.ic_notification_bell
                )

                val appIconImage = view.findViewById<ImageView>(R.id.appIconImage)
                val fallbackIndicator = view.findViewById<View>(R.id.fallbackIndicator)

                if (base64Icon != null && base64Icon.isNotEmpty()) {
                    try {
                        val decodedString = Base64.decode(base64Icon, Base64.DEFAULT)
                        val decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.size)
                        if (decodedByte != null) {
                            appIconImage?.setImageBitmap(decodedByte)
                            appIconImage?.visibility = View.VISIBLE
                            fallbackIndicator?.visibility = View.GONE
                        } else {
                            appIconImage?.visibility = View.GONE
                            fallbackIndicator?.visibility = View.VISIBLE
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to decode base64 icon: ${e.message}")
                        appIconImage?.visibility = View.GONE
                        fallbackIndicator?.visibility = View.VISIBLE
                    }
                } else {
                    appIconImage?.visibility = View.GONE
                    fallbackIndicator?.visibility = View.VISIBLE
                }

                // Action row + remote-key hints, driven by category. Both buttons
                // only dismiss the overlay early — there is no relay of a real
                // Accept/Answer action back to the phone (out of scope).
                val actionRow = view.findViewById<View>(R.id.actionRow)
                val primaryButton = view.findViewById<Button>(R.id.primaryActionButton)
                val secondaryButton = view.findViewById<Button>(R.id.secondaryActionButton)
                val remoteHintRow = view.findViewById<View>(R.id.remoteHintRow)

                when (category) {
                    "voice_call" -> {
                        actionRow?.visibility = View.VISIBLE
                        primaryButton?.text = "Accept"
                        secondaryButton?.text = "Decline"
                    }
                    "video_call" -> {
                        actionRow?.visibility = View.VISIBLE
                        primaryButton?.text = "Answer"
                        secondaryButton?.text = "Dismiss"
                    }
                    "message" -> {
                        actionRow?.visibility = View.VISIBLE
                        primaryButton?.text = "Read More"
                        secondaryButton?.text = "Dismiss"
                    }
                    else -> {
                        actionRow?.visibility = View.GONE
                    }
                }
                remoteHintRow?.visibility = if (isMessage) View.VISIBLE else View.GONE
                primaryButton?.setOnClickListener { hideNotificationOverlay() }
                secondaryButton?.setOnClickListener { hideNotificationOverlay() }

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    else
                        WindowManager.LayoutParams.TYPE_SYSTEM_ALERT,
                    // Touchable (not FLAG_NOT_TOUCHABLE) so the dismiss buttons work,
                    // but still FLAG_NOT_FOCUSABLE so the overlay never steals D-pad/
                    // keyboard focus from whatever the user is doing underneath.
                    // Known limitation: this makes the buttons mouse/touch-only —
                    // there's no real D-pad remote key handling (out of scope).
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                )

                layoutParams.gravity = when (overlayPosition) {
                    "top_left" -> Gravity.TOP or Gravity.START
                    "bottom_left" -> Gravity.BOTTOM or Gravity.START
                    "bottom_right" -> Gravity.BOTTOM or Gravity.END
                    else -> Gravity.TOP or Gravity.END
                }
                layoutParams.x = 80
                layoutParams.y = 80

                windowManager?.addView(overlayView, layoutParams)
                Log.d(TAG, "Overlay displayed: $title")
                playAlertSound(alertSoundUri)

                // Add fade-in animation
                overlayView?.alpha = 0f
                overlayView?.animate()?.alpha(1f)?.setDuration(300)?.start()

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
            val viewToRemove = overlayView
            val wm = windowManager
            overlayView = null
            removeRunnable?.let { handler.removeCallbacks(it) }
            removeRunnable = null

            try {
                viewToRemove?.animate()?.alpha(0f)?.setDuration(300)?.withEndAction {
                    try {
                        wm?.removeView(viewToRemove)
                        Log.d(TAG, "Overlay removed.")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to remove overlay view: ${e.message}")
                    }
                }?.start()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to animate overlay removal: ${e.message}")
                try {
                    wm?.removeView(viewToRemove)
                } catch (e2: Exception) {
                    // Ignore
                }
            }
        }
    }
}
