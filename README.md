# Dự án: TV Notification Mirror (Gương Thông Báo Lên TV)

Tài liệu này phác thảo ý tưởng và thiết kế kỹ thuật cho ứng dụng **TV Notification Mirror** - ứng dụng truyền thông báo từ điện thoại (Android) lên màn hình TV (Android TV) tương tự như cách hoạt động của đồng hồ thông minh (Smartwatch).

## Danh mục tài liệu

Để hiểu rõ hơn về dự án, vui lòng đọc các tài liệu chi tiết sau:

1. **[Tài liệu Yêu cầu Sản phẩm (PRD)](file:///e:/Projects/Dashboard%20Clock/doc/prd.md)**
   * Định nghĩa tính năng cho ứng dụng Điện thoại và ứng dụng TV.
   * Trải nghiệm người dùng (UX) và Giao diện (UI) trên TV.
   * Các kịch bản sử dụng thực tế.

2. **[Kiến trúc Hệ thống & Kỹ thuật (Architecture)](file:///e:/Projects/Dashboard%20Clock/doc/architecture.md)**
   * Mô hình kết nối giữa Điện thoại và TV (mDNS, WebSockets, Local Network).
   * Các thư viện (packages) Flutter đề xuất.
   * Giải pháp bảo mật và tối ưu năng lượng.

3. **[Thiết kế Kỹ thuật Android & Flutter (Technical Design)](file:///e:/Projects/Dashboard%20Clock/doc/technical_design.md)**
   * Cách lắng nghe thông báo trên Android (`NotificationListenerService`).
   * Hiển thị đè lên ứng dụng khác trên Android TV (`SYSTEM_ALERT_WINDOW`).
   * Quản lý chạy ngầm (Background Service) và duy trì kết nối.

## Ý tưởng cốt lõi (Core Concept)

Khi người dùng đang xem TV (Netflix, YouTube, Truyền hình cáp...), họ thường bỏ lỡ các thông báo quan trọng từ điện thoại (cuộc gọi, tin nhắn Zalo/Messenger, SMS) do điện thoại để ở xa hoặc để chế độ im lặng.

Giải pháp:
* **Ứng dụng trên Điện thoại (Phone App):** Chạy ngầm, tự động bắt các thông báo mới và gửi qua mạng Wi-Fi nội bộ đến TV.
* **Ứng dụng trên TV (TV App):** Chạy ngầm trên Android TV, khi nhận được thông báo từ điện thoại sẽ hiển thị một góc nhỏ trên màn hình (dạng Toast/Overlay) trong vài giây rồi biến mất, không làm gián đoạn trải nghiệm xem TV.
* **Đặc trưng:** Hoạt động hoàn toàn trong mạng cục bộ (không cần server internet), bảo mật thông tin, độ trễ cực thấp.
