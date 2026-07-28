# Phone App UI — 4-tab bottom nav redesign

> Nguồn tham chiếu bố cục: `doc/design/stitch/mobile/` (`DESIGN.md`, `WIREFRAME.md` + 4 màn
> Home/Devices/Notifications/Settings, mockup "Cinema Mobile"). Mockup dùng theme riêng
> (navy/blue/teal, font Geist/Inter, glassmorphism/blur/gradient) — **xung đột với rule
> "chỉ default Yaru/Material theme" trong `CLAUDE.md`**. Quyết định đã chốt với người dùng:
> **chỉ lấy bố cục/wireframe, giữ nguyên 100% Yaru + Material default widget** — không màu,
> gradient, blur, hay font tuỳ chỉnh nào được copy từ mockup.

## Điều hướng

Thay `DefaultTabController` 3-tab (`YaruTabBar` trong `AppBar.bottom`) bằng Material
`NavigationBar` 4-tab thật ở đáy màn hình: **Home / Alerts / Devices / Settings**, dùng icon
`YaruIcons.home` / `.notification` / `.computer` / `.settings`. Trạng thái tab hiện tại quản lý
bởi `phone/lib/providers/phone_nav_provider.dart` (`enum PhoneNavPage`, `@riverpod class
PhoneNavIndex`) — mirror y hệt pattern `tv/lib/providers/tv_nav_provider.dart` bên TV, cho phép
đổi tab từ nơi khác (vd. nút "View All" ở Home nhảy sang Alerts).

`PermissionBanner` vẫn nằm phía trên body, phía dưới `AppBar`, áp dụng cho mọi tab — không đổi.

## Ánh xạ nội dung cũ → trang mới

| Trang mới | File | Nội dung |
|---|---|---|
| **Home** | `phone/lib/screens/home/phone_home_screen.dart` | Tóm tắt kết nối (đọc-only, không nút), Quick Actions (Send Test Notification + Mirror Phone Notifications master switch), Recent Activity (3 mục gần nhất) + "View All" nhảy sang Alerts |
| **Alerts** | `phone/lib/screens/alerts/phone_alerts_screen.dart` | Toàn bộ lịch sử (thay `HistoryTab`) + `YaruSearchField` lọc client-side theo title/text/appName + nút Clear All (`historyProvider.clearHistory()`) |
| **Devices** | `phone/lib/screens/devices/phone_devices_screen.dart` | Gần như nguyên `ConnectTab` cũ: `StatusCard` (kết nối + DND + disconnect + send test/scan again) + nút Scan QR / Connect IP + danh sách TV phát hiện được |
| **Settings** | `phone/lib/screens/settings/phone_settings_screen.dart` + part files | Master mirror switch, `QuietHoursCard`, `KeywordFilterCard`, `OverlaySettingsCard` (đã đổi sang `AnchorPositionPicker`+`ValueStepper`), link sang `phone_app_filters_screen.dart`, Account/Support stub (Version thật qua `package_info_plus`) |

**Quyết định phạm vi khác:**
- Chỉ hiển thị 1 TV đã pair thật (kiến trúc hiện tại chỉ hỗ trợ 1 TV/lúc), **không** fake ra "2
  TV" như mockup.
- "Atmosphere Card" (ảnh phòng chiếu phim trang trí) trong mockup Home bị **bỏ hẳn** — không có
  dữ liệu thật, không liên quan tính năng mirror, cùng tinh thần với việc bỏ "Setup Guide" khỏi
  nav rail TV.

## Logic thật mới thêm (không phải chỉ UI)

- `History.clearHistory()` (`phone_providers.dart`) — nút Clear All ở Alerts.
- `AppSettings.masterMirrorEnabled` (mặc định `true`, `filter_service.dart`) — khi tắt, toàn bộ
  pipeline mirror trong `background_service.dart`'s `notificationService.notificationStream.listen`
  bỏ qua hoàn toàn notification thật (không mirror sang TV), độc lập với keyword/quiet-hours/app
  filter hiện có. (Nút "Send Test Notification" ở Home gọi thẳng `connectorProvider.sendNotification`,
  không qua pipeline này, nên vẫn hoạt động kể cả khi tắt — đúng ý nghĩa "test thủ công".)
- `AnchorPositionPicker` + `ValueStepper`: chuyển từ `tv/lib/widgets/` sang `shared/lib/widgets/`
  để 2 app dùng chung — `phone`'s `OverlaySettingsCard` giờ dùng grid 2×2 (thay `DropdownButton`)
  và stepper hai nút (thay `Slider`), nhất quán với TV Settings.
- `package_info_plus` thêm vào `phone/pubspec.yaml` cho Version thật ở Support section.

## File cũ đã xoá

`phone/lib/widgets/connect/connect_tab.dart`, `phone/lib/widgets/filters/filters_tab.dart`,
`phone/lib/widgets/history/history_tab.dart` (nội dung đã chuyển hết sang các trang mới ở trên).
Giữ nguyên `status_card.dart`, `device_list_tile.dart`, `history_item_card.dart`,
`quiet_hours_card.dart`, `keyword_filter_card.dart`, `overlay_settings_card.dart` (sửa nội dung
tại chỗ), `app_filter_tile.dart`, `permission_banner.dart`.

## Verified on-device (emulator-5554)

- Điều hướng 4 tab qua `NavigationBar` hoạt động đúng, không lỗi layout.
- Send Test Notification → xuất hiện ở Home Recent Activity và Alerts.
- Alerts: search + Clear All hoạt động.
- Devices: hiển thị đúng trạng thái Not Connected/Connected, Scan QR/Connect IP/Available TVs.
- Settings: Quiet Hours, Blocked Keywords, TV Overlay Settings (anchor grid 2×2 + stepper),
  App Filters sub-screen (danh sách app thật + icon thật), Account/Support stub, Version thật
  (`1.0.16+16`) đều render đúng theo default Yaru/Material theme, không có style tuỳ chỉnh.
