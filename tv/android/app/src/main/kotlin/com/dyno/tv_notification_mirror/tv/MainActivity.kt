package com.dyno.tv_notification_mirror.tv

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivityTV"
        private const val CHANNEL = "com.dyno.tv_notification_mirror/overlay"
        private const val REQUEST_PICK_ALERT_SOUND = 4201
    }

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
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(hasOverlayPermission())
                }
                "requestPermission" -> {
                    result.success(requestOverlayPermission())
                }
                "checkNotificationPermission" -> {
                    result.success(hasNotificationPermission())
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                "showOverlay" -> {
                    OverlayManager.show(
                        this,
                        call.argument<String>("title") ?: "",
                        call.argument<String>("text") ?: "",
                        call.argument<String>("appName") ?: "",
                        call.argument<String>("base64Icon"),
                        call.argument<String>("overlayPosition"),
                        call.argument<Int>("duration") ?: 5000,
                        call.argument<String>("category") ?: "generic",
                        call.argument<Double>("overlayOpacity") ?: 0.95,
                        call.argument<String>("alertSoundUri"),
                    )
                    result.success(true)
                }
                "hideOverlay" -> {
                    OverlayManager.hide()
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

    /// Attempts to open the overlay-permission settings screen. Returns whether
    /// a suitable screen could be launched — Fire TV has no "Display over other
    /// apps" page for third-party apps, so the caller falls back to ADB guidance.
    private fun requestOverlayPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val candidates = listOf(
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")),
            Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION),
        )
        for (intent in candidates) {
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                Log.d(TAG, "Overlay settings not available, trying next: ${e.message}")
            }
        }
        return false
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
}
