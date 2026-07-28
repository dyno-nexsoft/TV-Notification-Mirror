# Thiết kế Kỹ thuật Android & Flutter - TV Notification Mirror

Tài liệu này hướng dẫn chi tiết cách triển khai các thành phần native Android trong Flutter để lắng nghe thông báo trên điện thoại và hiển thị Overlay trên Android TV.

---

## 1. Triển khai phía Điện thoại (Phone Side)

Để đọc được thông báo của các ứng dụng khác, ta phải sử dụng dịch vụ hệ thống `NotificationListenerService` của Android.

### 1.1. Khai báo Service trong `AndroidManifest.xml`
Thêm cấu hình sau vào trong thẻ `<application>` của file `android/app/src/main/AndroidManifest.xml`:

```xml
<service android:name=".MyNotificationListener"
         android:label="TV Notification Mirror Listener"
         android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
         android:exported="true">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

### 1.2. Mã nguồn Kotlin (`MyNotificationListener.kt`)
Tạo file `MyNotificationListener.kt` để bắt sự kiện thông báo và truyền sang Dart/Flutter thông qua **MethodChannel** hoặc **EventChannel**:

```kotlin
package com.dyno.tv_notification_mirror.phone

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import androidx.localbroadcastmanager.content.LocalBroadcastManager

class MyNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val id = sbn.id.toString()
        val postTime = sbn.postTime

        // Phát Broadcast nội bộ để Flutter Service nhận được
        val intent = Intent("NEW_NOTIFICATION")
        intent.putExtra("id", id)
        intent.putExtra("packageName", packageName)
        intent.putExtra("title", title)
        intent.putExtra("text", text)
        intent.putExtra("postTime", postTime)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        val intent = Intent("REMOVED_NOTIFICATION")
        intent.putExtra("id", sbn.id.toString())
        intent.putExtra("packageName", sbn.packageName)
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent)
    }
}
```

### 1.3. Kết nối với Flutter thông qua EventChannel
Trong `MainActivity.kt`, nhận Broadcast và gửi luồng dữ liệu thông báo về Flutter:

```kotlin
// Trong MainActivity.kt
private val CHANNEL_NOTIFICATION_EVENT = "com.dyno.tv_notification_mirror/notifications"

// Cài đặt EventChannel để truyền dữ liệu thời gian thực sang Flutter Dart
EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NOTIFICATION_EVENT)
    .setStreamHandler(object : EventChannel.StreamHandler {
        private var receiver: BroadcastReceiver? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent != null) {
                        val data = mapOf(
                            "event" to intent.action,
                            "id" to intent.getStringExtra("id"),
                            "packageName" to intent.getStringExtra("packageName"),
                            "title" to intent.getStringExtra("title"),
                            "text" to intent.getStringExtra("text"),
                            "postTime" to intent.getLongExtra("postTime", 0L)
                        )
                        events?.success(data)
                    }
                }
            }
            val filter = IntentFilter().apply {
                addAction("NEW_NOTIFICATION")
                addAction("REMOVED_NOTIFICATION")
            }
            LocalBroadcastManager.getInstance(applicationContext).registerReceiver(receiver!!, filter)
        }

        override fun onCancel(arguments: Any?) {
            receiver?.let {
                LocalBroadcastManager.getInstance(applicationContext).unregisterReceiver(it)
            }
        }
    })
```

---

## 2. Triển khai phía TV (TV Side)

Android TV yêu cầu khả năng vẽ đè cửa sổ lên các ứng dụng đang chạy khác (như YouTube, Netflix). Điều này đòi hỏi quyền vẽ đè màn hình (`SYSTEM_ALERT_WINDOW`).

### 2.1. Cấp quyền trong `AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<!-- Cần cho phép TV tự chạy khi khởi động -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### 2.2. Hiển thị Overlay sử dụng `WindowManager` trong Android
Trong Flutter, cửa sổ UI thông thường không thể vẽ đè lên ứng dụng hệ thống khác nếu ứng dụng Flutter đang chạy ngầm. Chúng ta phải gọi native Android qua `MethodChannel` để yêu cầu hiển thị một cửa sổ Android Native Custom View thông qua `WindowManager`.

```kotlin
// Hàm Kotlin tạo Overlay Window
fun showNotificationOverlay(context: Context, title: String, text: String, appName: String) {
    val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    
    // Thiết lập Layout Parameters cho cửa sổ Overlay
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

    // Xác định vị trí (ví dụ: Góc trên bên phải, có căn chỉnh lề)
    layoutParams.gravity = Gravity.TOP or Gravity.END
    layoutParams.x = 50 // Cách lề phải 50px
    layoutParams.y = 50 // Cách lề trên 50px

    // Tạo Custom View chứa thông báo (sử dụng LayoutInflater từ XML layout)
    val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
    val overlayView = inflater.inflate(R.layout.notification_overlay_layout, null)
    
    // Set text cho các TextView
    overlayView.findViewById<TextView>(R.id.titleText).text = title
    overlayView.findViewById<TextView>(R.id.bodyText).text = text
    overlayView.findViewById<TextView>(R.id.appNameText).text = appName

    // Thêm View vào Window
    windowManager.addView(overlayView, layoutParams)

    // Tự động gỡ bỏ View sau 5 giây
    Handler(Looper.getMainLooper()).postDelayed({
        try {
            windowManager.removeView(overlayView)
        } catch (e: Exception) {
            // Đề phòng trường hợp view đã bị gỡ bỏ trước đó
        }
    }, 5000)
}
```

*Lưu ý: Thiết kế file layout `notification_overlay_layout.xml` cần bo góc, có màu tối mờ (glassmorphism hoặc đen mờ) để đảm bảo tính thẩm mỹ cao.*

---

## 3. Khởi động cùng TV & Watchdog (Autostart & Keep-alive)

Để ứng dụng TV hoạt động ngay khi TV bật mà không cần người dùng mở ứng dụng thủ công, và duy trì service ngay cả khi bị Android kill.

### 3.1. BootReceiver — Khởi động khi TV bật

```kotlin
package com.dyno.tv_notification_mirror.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val launchOnBoot = prefs.getBoolean("flutter.tv_launch_on_boot", true)
            if (!launchOnBoot) return

            val serviceIntent = Intent().apply {
                setClassName(context.packageName, "id.flutter.flutter_background_service.BackgroundService")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}
```

### 3.2. Watchdog AlarmManager — Chống service bị kill

Khi Android kill Foreground Service (do thiếu RAM hoặc chính sách OEM), tiến trình Flutter biến mất hoàn toàn. Giải pháp là dùng **AlarmManager** native — độc lập với Dart VM — để tự động restart service định kỳ.

**Cơ chế:**
- `TvApplication.onCreate()` schedule một `AlarmManager` với `setInexactRepeating(ELAPSED_REALTIME_WAKEUP, ...)` mỗi 5 phút.
- Khi alarm fire, `RestartAlarmReceiver` nhận broadcast và gọi `startForegroundService()`.
- Hành động này idempotent: nếu service đang chạy, Android sẽ ignore; nếu đã chết, service được khởi động lại.

**RestartAlarmReceiver.kt:**
```kotlin
package com.dyno.tv_notification_mirror.tv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class RestartAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_RESTART_SERVICE) {
            val serviceIntent = Intent().apply {
                setClassName(context.packageName, "id.flutter.flutter_background_service.BackgroundService")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }

    companion object {
        const val ACTION_RESTART_SERVICE = "com.dyno.tv_notification_mirror.RESTART_SERVICE"
        const val REQUEST_CODE = 1001
        const val INTERVAL_MS = 5 * 60 * 1000L // 5 phút
    }
}
```

**Đăng ký trong AndroidManifest.xml:**
```xml
<receiver android:name=".RestartAlarmReceiver" 
          android:enabled="true" 
          android:exported="true" />
```

**TvApplication.kt schedule alarm:**
```kotlin
class TvApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        scheduleWatchdogAlarm()
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
```

---

## 4. Phone Auto-reconnect — Exponential Backoff

Khi WebSocket bị đứt (TV restart, network glitch, TV service bị kill), phone tự động reconnect với backoff:

- **Attempt 0:** 5 giây
- **Attempt 1:** 10 giây
- **Attempt 2:** 20 giây
- **Attempt 3:** 40 giây
- **Attempt 4+:** 60 giây (cap)

Công thức: `(5 * 2^attempt).clamp(5, 60)`. Reset về 0 khi kết nối thành công.

```dart
void _scheduleReconnect() {
  _reconnectTimer?.cancel();
  final backoff = Duration(
    seconds: (5 * (1 << _reconnectAttempt)).clamp(5, 60),
  );
  _reconnectAttempt++;
  _reconnectTimer = Timer(backoff, () async {
    if (!_isConnecting) await connectToSavedTv();
  });
}
```

Kết hợp với mDNS discovery: phone tự động kết nối lại khi phát hiện lại TV đã lưu trong mạng.

---

## 5. Tối ưu hóa UI cho Android TV (Leanback Guidelines)

Khi xây dựng giao diện ứng dụng cấu hình trên Android TV bằng Flutter, cần lưu ý:
1. **Hỗ trợ D-pad hoàn toàn:**
   * Sử dụng widget `Focus` hoặc `FocusableActionDetector` của Flutter.
   * Mọi nút bấm (Button), danh sách (ListView) phải có trạng thái thay đổi rõ ràng khi được focus (ví dụ: đổi màu viền, phóng to nhẹ 1.05x).
2. **Kích thước giao diện:**
   * Tránh dùng kích thước cố định bằng pixel nhỏ. Thiết kế layout tỷ lệ với chiều cao màn hình (sử dụng `MediaQuery`).
   * Phông chữ tối thiểu cho TV là 16sp cho chữ thường và 24sp-32sp cho tiêu đề.
3. **Tránh cuộn trang quá nhiều:** Thiết kế dạng Tab ngang hoặc lưới lớn (Grid) trực quan dễ điều hướng bằng Remote control.
