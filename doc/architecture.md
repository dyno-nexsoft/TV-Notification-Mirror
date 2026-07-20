# Kiến trúc Hệ thống & Kỹ thuật - TV Notification Mirror

Tài liệu này mô tả kiến trúc kỹ thuật, mô hình kết nối mạng và các thành phần công nghệ được sử dụng để xây dựng ứng dụng **TV Notification Mirror**.

---

## 1. Kiến trúc tổng thể (High-level Architecture)

Hệ thống hoạt động theo mô hình **Client-Server cục bộ (Local Peer-to-Peer)**, trong đó:
* **TV (Android TV) đóng vai trò là Server:** Lắng nghe các kết nối đến thông qua giao thức WebSocket và HTTP, đồng thời quảng bá sự hiện diện của mình qua mạng Wi-Fi cục bộ sử dụng mDNS.
* **Điện thoại (Android Phone) đóng vai trò là Client:** Tìm kiếm TV qua mDNS, thiết lập kết nối WebSocket duy nhất và truyền tải dữ liệu thông báo dưới dạng JSON.

```mermaid
graph TD
    subgraph Mạng Wi-Fi Cục bộ (Local Wi-Fi Network)
        subgraph Điện thoại (Client)
            A[Notification Listener Service] -->|Lọc & xử lý| B[Notification Manager]
            B -->|JSON qua WebSocket Client| C[Connection Manager]
            C -->|Quét mDNS| D[mDNS Discovery]
        end

        subgraph Android TV (Server)
            G[mDNS Advertiser] -.->|Phát sóng dịch vụ| D
            E[WebSocket Server] <-->|Kết nối / Xác thực| C
            E -->|Dữ liệu thông báo| F[System Overlay Manager]
            F -->|Hiển thị pop-up đè màn hình| H[Leanback/TV UI]
        end
    end
```

---

## 2. Giao thức Truyền thông (Communication Protocol)

### 2.1. Phát hiện thiết bị (Device Discovery)
* Sử dụng **Multicast DNS (mDNS)** thông qua DNS Service Discovery (DNS-SD).
* TV đăng ký dịch vụ với tên dịch vụ dạng: `_tvmirror._tcp`.
* Dữ liệu TXT Record của mDNS trên TV có thể chứa:
  * `device_name`: Tên TV (ví dụ: "Sony Bravia 4K", "TCL Living Room").
  * `port`: Cổng của WebSocket Server.
  * `version`: Phiên bản ứng dụng.

### 2.2. Ghép đôi & Xác thực (Pairing & Authentication)
Để tránh trường hợp người lạ trong cùng mạng Wi-Fi gửi thông báo phá hoại lên TV, cần có cơ chế xác thực:
1. **Khởi tạo:** Client gửi một HTTP POST request chứa tên điện thoại đến `/api/pair`.
2. **Hiển thị PIN:** TV tạo ngẫu nhiên mã PIN 4 chữ số và hiển thị lên màn hình.
3. **Xác thực:** Client gửi mã PIN đã nhập lên `/api/pair/confirm`.
4. **Cấp Token:** Nếu PIN đúng, TV sinh ra một chuỗi token bí mật mã hóa ngẫu nhiên và gửi lại cho Client. Cả hai lưu trữ Token này (ở Client sử dụng `flutter_secure_storage`, ở Server lưu danh sách Token hợp lệ trong Database cục bộ).
5. **Kết nối WebSocket:** Khi thiết lập kết nối WebSocket, Client gửi Token trong phần Header (`Authorization: Bearer <Token>`). TV sẽ ngắt kết nối ngay lập tức nếu Token không hợp lệ.

### 2.3. Cấu trúc gói tin dữ liệu (JSON Schema)

#### Gói tin thông báo (Notification Payload)
Khi điện thoại bắt được thông báo mới, nó sẽ gửi một JSON object qua WebSocket:
```json
{
  "event": "notification_new",
  "timestamp": 1784563820000,
  "data": {
    "id": "10023",
    "package_name": "com.whatsapp",
    "app_name": "WhatsApp",
    "title": "Nguyễn Văn A",
    "text": "Tối nay đi đá bóng không?",
    "post_time": 1784563819000,
    "icon": "base64_encoded_png_icon_string" 
  }
}
```
*Lưu ý: Trường `icon` chứa ảnh icon của ứng dụng được mã hóa Base64 (hoặc gửi qua một HTTP endpoint riêng trên điện thoại để TV tải về khi cần nhằm tối ưu hóa dung lượng gói WebSocket).*

#### Gói tin điều khiển / Đồng bộ hủy (Cancel Notification Payload)
Nếu thông báo trên điện thoại bị xóa hoặc đã đọc, TV cũng sẽ tự động ẩn pop-up đó (nếu nó đang hiển thị):
```json
{
  "event": "notification_removed",
  "timestamp": 1784563825000,
  "data": {
    "id": "10023",
    "package_name": "com.whatsapp"
  }
}
```

---

## 3. Lựa chọn Thư viện Flutter (Flutter Stack Selection)

### 3.1. Các thư viện dùng chung (Shared Packages)
* `flutter_bloc` hoặc `provider`: Quản lý trạng thái (State Management).
* `shared_preferences` hoặc `hive`: Lưu cấu hình cài đặt cục bộ.
* `flutter_secure_storage`: Lưu trữ khóa token xác thực an toàn.

### 3.2. Thư viện cho Điện thoại (Phone Client)
* `nsd` hoặc `bonsoir`: Thực hiện quét mDNS tìm TV trong mạng nội bộ.
* `web_socket_channel`: Kết nối WebSocket client ổn định đến TV.
* Thư viện lắng nghe thông báo: Viết Native code (Kotlin) cho `NotificationListenerService` thông qua **Method Channel**, hoặc dùng package `notifications_listener_service` (nếu có và ổn định).

### 3.3. Thư viện cho TV (TV Server)
* `shelf` và `shelf_web_socket`: Dùng để dựng HTTP và WebSocket server trực tiếp trên Android TV bằng Dart.
* `nsd` hoặc `bonsoir`: Đăng ký và quảng bá dịch vụ mDNS.
* `system_alert_window` hoặc Native Kotlin implementation: Để hiển thị cửa sổ overlay (vẽ đè lên các ứng dụng khác).

---

## 4. Các thách thức kỹ thuật & Giải pháp (Challenges & Solutions)

| Thách thức | Nguyên nhân | Giải pháp đề xuất |
| :--- | :--- | :--- |
| **TV tắt màn hình hoặc Standby** | Khi Android TV vào chế độ sleep, Wi-Fi có thể bị ngắt kết nối để tiết kiệm điện, Server sẽ chết. | Thiết lập cơ chế gửi gói tin Heartbeat (Ping/Pong) mỗi 10-30 giây. Khi TV bật lại (wake up), ứng dụng TV phải tự khởi động lại dịch vụ qua `BroadcastReceiver` lắng nghe sự kiện `ACTION_SCREEN_ON` hoặc `ACTION_BOOT_COMPLETED`. |
| **IP của TV bị thay đổi** | Router Wi-Fi cấp IP động cho TV mỗi khi kết nối lại. | Điện thoại không lưu IP cứng của TV. Mỗi lần kết nối, Điện thoại sẽ dùng mDNS để phân giải tên TV thành IP hiện tại. |
| **Ứng dụng Điện thoại bị hệ thống khai tử (Killed)** | Cơ chế tối ưu pin của Android rất nghiêm ngặt đối với ứng dụng chạy ngầm dài hạn. | 1. Yêu cầu người dùng tắt "Tối ưu hóa pin" (Battery Optimization) cho ứng dụng.<br>2. Chạy dịch vụ dưới dạng **Foreground Service** hiển thị một thông báo cố định trên thanh trạng thái (Sticky Notification). |
| **Dung lượng ảnh Icon lớn** | Truyền ảnh icon ứng dụng dạng Base64 qua WebSocket có thể gây lag. | Tách riêng việc truyền text và ảnh. TV có thể tải icon bằng cơ chế bộ nhớ đệm (Cache). Hoặc Client chỉ gửi tên package (`com.whatsapp`), TV sẽ tự dùng bộ icon mặc định của các app phổ biến hoặc lưu trữ cục bộ. |
