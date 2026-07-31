package com.dyno.tv_notification_mirror.tv

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Base64
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView

/// Owns the SYSTEM_ALERT_WINDOW overlay and its lifecycle. Lives as a process
/// singleton so the overlay can be driven from the background service (via a
/// broadcast) even after the UI Activity — which previously owned this logic —
/// has been destroyed by swiping the app away from the recents screen.
object OverlayManager {

    private const val TAG = "OverlayManager"

    const val ACTION_SHOW_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_OVERLAY"
    const val ACTION_HIDE_OVERLAY = "com.dyno.tv_notification_mirror.HIDE_OVERLAY"
    const val ACTION_SHOW_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.SHOW_STATUS_OVERLAY"
    const val ACTION_HIDE_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.HIDE_STATUS_OVERLAY"
    const val ACTION_UPDATE_STATUS_OVERLAY = "com.dyno.tv_notification_mirror.UPDATE_STATUS_OVERLAY"

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var removeRunnable: Runnable? = null

    // Debug status HUD state (persistent, shown until explicitly hidden).
    private var statusView: View? = null
    private var statusWindowManager: WindowManager? = null

    /// Applies opacity (0..1) to the overlay root by adjusting its alpha.
    private fun applyOverlayOpacity(opacity: Double) {
        overlayView?.alpha = opacity.coerceIn(0.0, 1.0).toFloat()
    }

    fun show(
        context: Context,
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
            hide()

            if (!hasOverlayPermission(context)) {
                Log.w(TAG, "Overlay permission not granted. Cannot show overlay.")
                return@post
            }

            try {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater

                val view = inflater.inflate(R.layout.notification_overlay_layout, null)
                overlayView = view
                windowManager = wm

                view.findViewById<TextView>(R.id.titleText)?.text = title
                view.findViewById<TextView>(R.id.bodyText)?.text = text
                view.findViewById<TextView>(R.id.timeText)?.text = "Just now"
                applyOverlayOpacity(opacity)

                val isCall = category == "voice_call" || category == "video_call"
                val isMessage = category == "message"

                // Header icon + app name
                val headerIcon = view.findViewById<ImageView>(R.id.headerIcon)
                val appNameText = view.findViewById<TextView>(R.id.appNameText)
                when (category) {
                    "voice_call" -> {
                        headerIcon?.setImageResource(R.drawable.ic_call)
                        appNameText?.text = "INCOMING CALL"
                    }
                    "video_call" -> {
                        headerIcon?.setImageResource(R.drawable.ic_videocam)
                        appNameText?.text = "INCOMING VIDEO CALL"
                    }
                    "message" -> {
                        headerIcon?.setImageResource(R.drawable.ic_chat)
                        appNameText?.text = appName.uppercase()
                    }
                    else -> {
                        headerIcon?.setImageResource(R.drawable.ic_notification_bell)
                        appNameText?.text = appName.uppercase()
                    }
                }

                // Avatar: use base64 icon for app icon or generic; use person placeholder for calls/messages
                val avatarImage = view.findViewById<ImageView>(R.id.avatarImage)
                val fallbackGlyph = view.findViewById<ImageView>(R.id.fallbackGlyph)
                val fallbackIndicator = view.findViewById<View>(R.id.fallbackIndicator)
                val onlineDot = view.findViewById<ImageView>(R.id.onlineDot)

                val hasBase64Icon = base64Icon != null && base64Icon.isNotEmpty()
                if (hasBase64Icon && !isCall) {
                    try {
                        val decodedString = Base64.decode(base64Icon, Base64.DEFAULT)
                        val decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.size)
                        if (decodedByte != null) {
                            avatarImage?.setImageBitmap(decodedByte)
                            avatarImage?.visibility = View.VISIBLE
                            fallbackIndicator?.visibility = View.GONE
                        } else {
                            avatarImage?.visibility = View.GONE
                            fallbackIndicator?.visibility = View.VISIBLE
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to decode base64 icon: ${e.message}")
                        avatarImage?.visibility = View.GONE
                        fallbackIndicator?.visibility = View.VISIBLE
                    }
                } else {
                    avatarImage?.visibility = View.GONE
                    fallbackIndicator?.visibility = View.VISIBLE
                }

                fallbackGlyph?.setImageResource(
                    if (isCall || isMessage) R.drawable.ic_person_placeholder
                    else R.drawable.ic_notification_bell
                )
                onlineDot?.visibility = if (isMessage) View.VISIBLE else View.GONE

                // Action row + remote-key hints
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
                primaryButton?.setOnClickListener { hide() }
                secondaryButton?.setOnClickListener { hide() }

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

                wm.addView(overlayView, layoutParams)
                Log.d(TAG, "Overlay displayed: $title")
                playAlertSound(context, alertSoundUri)

                // Slide-in animation from right (matching design's toast-in).
                // Hardware layer avoids per-frame re-rasterization, which
                // otherwise flickers on emulators/SwiftShader during fades.
                val displayMetrics = context.resources.displayMetrics
                val slidingIn = view
                slidingIn.setLayerType(View.LAYER_TYPE_HARDWARE, null)
                slidingIn.translationX = (displayMetrics.widthPixels * 0.3f).coerceAtLeast(200f)
                slidingIn.alpha = 0f
                slidingIn.animate()
                    ?.translationX(0f)
                    ?.alpha(1f)
                    ?.setDuration(500)
                    ?.withEndAction { slidingIn.setLayerType(View.LAYER_TYPE_NONE, null) }
                    ?.start()

                removeRunnable = Runnable {
                    hide()
                }
                handler.postDelayed(removeRunnable!!, duration.toLong())
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay view: ${e.message}")
            }
        }
    }

    fun hide() {
        if (overlayView != null && windowManager != null) {
            val viewToRemove = overlayView
            val wm = windowManager
            overlayView = null
            removeRunnable?.let { handler.removeCallbacks(it) }
            removeRunnable = null

            try {
                // Slide fully off-screen so the final animation frame (where
                // SwiftShader/emulator alpha compositing tends to flicker) is
                // no longer visible before removeView tears the window down.
                val displayMetrics = viewToRemove?.resources?.displayMetrics
                val offScreenX = ((displayMetrics?.widthPixels ?: 1280) + 200).toFloat()
                viewToRemove?.setLayerType(View.LAYER_TYPE_HARDWARE, null)
                viewToRemove?.animate()
                    ?.translationX(offScreenX)
                    ?.alpha(0f)
                    ?.setDuration(400)
                    ?.withEndAction {
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

    private fun hasOverlayPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }

    /// Displays the persistent debug status HUD (server state, connected
    /// clients, DND). Idempotent: a no-op if the HUD is already visible.
    fun showStatusOverlay(context: Context) {
        handler.post {
            if (statusView != null) return@post
            if (!hasOverlayPermission(context)) {
                Log.w(TAG, "Overlay permission not granted. Cannot show status overlay.")
                return@post
            }
            try {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
                val view = inflater.inflate(R.layout.debug_status_overlay_layout, null)
                statusView = view
                statusWindowManager = wm

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    else
                        WindowManager.LayoutParams.TYPE_SYSTEM_ALERT,
                    // NOT_TOUCHABLE so the HUD never blocks input; KEEP_SCREEN_ON
                    // so it stays visible while debugging on a real device.
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
                    PixelFormat.TRANSLUCENT
                )
                layoutParams.gravity = Gravity.TOP or Gravity.START
                layoutParams.x = 24
                layoutParams.y = 24
                wm.addView(view, layoutParams)
                Log.d(TAG, "Status overlay displayed.")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add status overlay view: ${e.message}")
            }
        }
    }

    /// Refreshes the HUD text. No-op if the HUD isn't currently visible.
    fun updateStatusOverlay(text: String) {
        handler.post {
            statusView?.findViewById<TextView>(R.id.statusText)?.text = text
        }
    }

    /// Removes the debug status HUD.
    fun hideStatusOverlay() {
        handler.post {
            val viewToRemove = statusView
            val wm = statusWindowManager
            statusView = null
            statusWindowManager = null
            if (viewToRemove != null && wm != null) {
                try {
                    wm.removeView(viewToRemove)
                    Log.d(TAG, "Status overlay removed.")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to remove status overlay: ${e.message}")
                }
            }
        }
    }

    private fun playAlertSound(context: Context, alertSoundUri: String?) {
        if (alertSoundUri == "silent") return
        try {
            val uri = if (alertSoundUri != null) {
                Uri.parse(alertSoundUri)
            } else {
                RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_NOTIFICATION)
            }
            RingtoneManager.getRingtone(context, uri)?.play()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play alert sound: ${e.message}")
        }
    }
}
