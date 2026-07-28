package com.dyno.tv_notification_mirror.phone

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // The notification-listener bridge is handled by the shared `native_bridge`
    // plugin (registered on both UI and background isolates). This class only
    // owns what must run on the UI Activity itself: the system ringtone picker
    // used for the phone's own "Send Test Notification" alert sound.

    companion object {
        private const val TAG = "MainActivityPhone"
        private const val CHANNEL = "com.dyno.tv_notification_mirror.phone/alertsound"
        private const val REQUEST_PICK_ALERT_SOUND = 4301
    }

    private var pendingAlertSoundResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAlertSound" -> pickAlertSound(result)
                "playAlertSound" -> {
                    playAlertSound(call.argument<String>("uri"))
                    result.success(true)
                }
                else -> result.notImplemented()
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
}
