# Quy tắc phát triển Dự án (TV-Notification-Mirror Rules)

Tài liệu này định nghĩa các quy tắc kỹ thuật và ràng buộc hành vi quan trọng dành cho các AI Agent (như Gemini) khi bảo trì và phát triển mã nguồn của dự án này.

---

## 1. Quy tắc Git và Đóng gói (Git & Release Rules)
* **Quy tắc tạo Tag:** Tuyệt đối **KHÔNG tự động tạo và push Git Tag** lên remote repository khi kết thúc task trừ khi được người dùng yêu cầu bằng văn bản rõ ràng. Chỉ thực hiện `git add` và `git commit` sau khi hoàn tất mỗi thay đổi.
* **Tên tệp APK Đóng gói:** Toàn bộ tệp cài đặt APK được đóng gói tự động qua GitHub Actions (cấu hình tại `.github/workflows/release.yml`) phải sử dụng tiền tố **`noti-mirror-`** (ví dụ: `noti-mirror-phone-v*.apk` và `noti-mirror-tv-v*.apk`) để phân biệt rõ ràng đây là ứng dụng nhận/gửi thông báo.

---

## 2. Quy tắc Android 14+ (Kotlin Broadcast Receiver)
* Khi đăng ký các bộ thu phát động (`registerReceiver`) trong mã nguồn Kotlin (ví dụ: `MainActivity.kt` của cả Phone và TV), bắt buộc phải kiểm tra phiên bản SDK:
  ```kotlin
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED) // Hoặc RECEIVER_NOT_EXPORTED tùy mục đích
  } else {
      registerReceiver(receiver, filter)
  }
  ```
* Việc gọi trực tiếp các hằng số flag xuất bản nhận tin trên các thiết bị chạy Android cũ (dưới API 33) mà không bao bọc kiểm tra phiên bản sẽ dẫn đến lỗi sập nguồn `NoSuchFieldError`.

---

## 3. Quy tắc dịch vụ chạy ngầm trên Android TV (Foreground Service & POST_NOTIFICATIONS)
* Ứng dụng TV sử dụng gói `flutter_background_service` để duy trì máy chủ WebSocket nhận thông báo từ điện thoại.
* **Yêu cầu loại dịch vụ (Foreground Service Type):** Bắt buộc phải khai báo loại dịch vụ là `connectedDevice` trong tệp `AndroidManifest.xml` của TV để tương thích với Android 14+:
  ```xml
  <service
      android:name="id.flutter.flutter_background_service.BackgroundService"
      android:foregroundServiceType="connectedDevice"
      android:exported="true" />
  ```
  Vài khai báo quyền tương ứng:
  `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />`
* **Ngăn ngừa crash sập nguồn khi khởi động (Android 13+):**
  * Android 13+ yêu cầu quyền `POST_NOTIFICATIONS` để đăng ký chạy Foreground Service. Nếu chưa được cấp quyền mà gọi chạy dịch vụ ngay lập tức sẽ gây crash `CannotPostForegroundServiceNotificationException`.
  * **Giải pháp:** Cài đặt thuộc tính cấu hình dịch vụ `autoStart: false`. Trong luồng giao diện khởi động của TV (`lib/main.dart`), phải kiểm tra và yêu cầu người dùng cấp đủ 2 quyền: **Vẽ đè màn hình (Overlay)** và **Thông báo (Notifications)** trước khi kích hoạt `startService()`.

---

## 4. Quy tắc Thiết kế Giao diện & Icon (Adaptive Icons & Banner)
* **Adaptive Icons cho Điện thoại:** Cấu hình launcher icon phải thiết lập đầy đủ dạng Adaptive Icon trong `pubspec.yaml` với mã màu nền `#210A3E` (màu tím đặc trưng trích xuất từ logo) và ảnh phủ `icon.png` để tránh việc hệ thống Android tự động nén icon hình vuông vào trong một viền tròn trắng xấu xí.
* **Banner TV 16:9:** Ảnh banner ngang cho TV (`tv_banner.png` nằm trong thư mục tài nguyên drawable của TV) phải được **cắt (crop) trực tiếp từ tâm** của ảnh logo vuông 1:1 gốc để đảm bảo tính đồng nhất 100% về họa tiết logo và dòng màu sắc chuyển đổi gradient.

---

## 5. Quy tắc Kiểm thử Mạng cục bộ trên Máy ảo (Emulator Loopback Testing)
* Do tường lửa NAT của các máy ảo Android độc lập, hai máy ảo chạy song song (Phone `emulator-5554` và TV `emulator-5556`) không thể tự động phát hiện nhau qua mDNS.
* **Quy trình thiết lập kết nối thử nghiệm:**
  1. Chạy chuyển tiếp cổng trên hệ điều hành host Windows:
     ```powershell
     adb -s emulator-5556 forward tcp:8080 tcp:8080
     ```
  2. Trên giao diện Điện thoại, chọn nhập IP thủ công và kết nối vào địa chỉ loopback đặc biệt dẫn tới Windows: **`10.0.2.2:8080`**.
  3. Nhập mã PIN hiển thị trên màn hình TV để hoàn tất ghép đôi.
