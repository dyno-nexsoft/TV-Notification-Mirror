# TV Notification Mirror — UI Design Spec (từ Stitch mockups)

> Nguồn: 8 màn hình Stitch trong `doc/design/stitch/` (project *TV Notification Sync*).
> Mục tiêu: wireframe hoá từng màn để dựng lại bằng **Yaru + Material + `shared`** theo đúng
> quy ước trong `CLAUDE.md`. Các mockup Stitch dùng theme tối / bo góc / accent xanh —
> **KHÔNG copy màu/kích thước inline**; chỉ dùng làm tham chiếu bố cục. Mọi khác biệt về
> màu sắc phải chỉnh trong theme toàn cục (`YaruAppTheme` / `shared`), không style trên từng widget.
>
> **✅ Đã triển khai đầy đủ** (xem §10 để biết chi tiết implementation cuối cùng và các điểm
> lệch so với kế hoạch ban đầu trong tài liệu này — tài liệu gốc bên dưới giữ nguyên làm lịch sử
> thiết kế, §10 là nguồn chính xác nhất về trạng thái code thật).

---

## 0. Quy ước áp dụng cho toàn bộ spec

Bám theo `CLAUDE.md`:

- **Chỉ default theme**: không `style:`, `color:`, `fontWeight:` trên widget lẻ. Muốn đổi → sửa theme global.
- **Private widget class** thay cho hàm build-widget: `class _HomeActionCard extends StatelessWidget`.
- **Theme access**: đầu `build` lấy `final theme = Theme.of(context);` (+ `theme.textTheme`, `theme.colorScheme`) rồi dùng biến đó.
- **Spacing**: dùng `spacing:` của `Column`/`Row`, không `SizedBox` chèn khoảng cách.
- **File < ~200–250 dòng** → tách bằng `part`/`part of`. **Hàm < ~30–50 dòng**.
- **Feedback lỗi**: qua provider `AppToast` + 1 `ref.listen` ở tầng gốc, không `try/catch`+`ScaffoldMessenger` trong widget.
- **Type annotation**: tuân `omit_local_variable_types` / `omit_obvious_property_types`.

Ký hiệu bảng: **Có sẵn** = widget Yaru/Material/`shared` dùng trực tiếp · **Tạo mới** = widget cần viết thêm (đặt trong `tv/lib/widgets/` hoặc `shared`).

---

## 1. Khung layout chung (áp dụng cho 4 màn full-page: Home, Settings, History, Manage Devices, Pair Device)

Tất cả màn "full app" đều là **master–detail**: nav rail trái cố định + vùng nội dung phải cuộn.

```
┌──────────────┬─────────────────────────────────────────────┐
│  [logo] NotifyTV                                           │
│  ● Standby   │   <Tiêu đề trang>                           │
│              │   <Phụ đề trang>                            │
│  ▸ Home      │                                             │
│  ▸ History   │   ┌──────────── nội dung detail ─────────┐  │
│  ▸ Manage    │   │                                      │  │
│  ▸ Pair      │   │   (cuộn dọc)                         │  │
│  ▸ Setup     │   │                                      │  │
│  ▸ Settings  │   └──────────────────────────────────────┘  │
│              │                                             │
│  🖥 sdk_..._arm64                                          │
└──────────────┴─────────────────────────────────────────────┘
```

| Vùng | Widget | Loại |
|------|--------|------|
| Khung master–detail | `YaruMasterDetailPage` (hoặc `YaruNavigationPage`) | Có sẵn |
| Rail điều hướng | `YaruNavigationRail` + `YaruNavigationRailItem` | Có sẵn |
| Header logo + trạng thái | **`_AppRailHeader`** (logo `Icon` + `Text` tên + `_StatusDot`) | Tạo mới |
| Chấm trạng thái ● | **`_StatusDot`** (dùng `YaruInfoBadge` hoặc `CircleAvatar` nhỏ) | Tạo mới |
| Tên thiết bị cuối rail | **`_RailDeviceFooter`** (`Icon` + `Text`) | Tạo mới |
| Tiêu đề + phụ đề trang | **`_PageHeader({title, subtitle})`** (`Column` 2 `Text` dùng `textTheme`) | Tạo mới |
| Vùng detail cuộn | `SingleChildScrollView` + `Column(spacing: …)` | Có sẵn |

> TV app hiện đã có nav-rail layout trong `tv/lib/screens/tv_main_screen.dart` — tái dùng, chỉ bổ sung
> `_AppRailHeader` / `_RailDeviceFooter` / `_PageHeader` nếu chưa có.

---

## 2. Màn Home (`01-notifytv-home.png`)

```
Home
┌───────────────────────────┐  ┌───────────────────────────┐
│ ▣  Pair New Device        │  │ ▣  Setup Guide            │
│    Scan QR to connect     │  │    Step-by-step ...       │
└───────────────────────────┘  └───────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ Notification Receiving                            [ ●──○ ] │
│ Receiving notifications from all connected devices        │
└──────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────┐
│ Do Not Disturb                                    [ ○──● ] │
│ Off                                                        │
│  ( 1 Hour ) ( 6 Hours ) ( Until Tomorrow )                 │
└──────────────────────────────────────────────────────────┘
```

| Thành phần | Widget | Loại |
|-----------|--------|------|
| 2 thẻ hành động (Pair / Setup) | **`_HomeActionCard({icon, title, subtitle, onTap})`** dựng trên `YaruBanner` hoặc `YaruSelectableContainer` | Tạo mới |
| Bố cục 2 thẻ ngang | `Row(spacing: …)` + `Expanded` | Có sẵn |
| Hàng "Notification Receiving" | `YaruSwitchListTile(title, subtitle, value, onChanged)` | Có sẵn |
| Hàng "Do Not Disturb" | `YaruSwitchListTile` | Có sẵn |
| Nhóm chip thời lượng DND | `YaruChoiceChipBar` **hoặc** `Wrap` + `YaruChoiceChip`/`ChoiceChip` | Có sẵn |
| Thẻ bọc cả nhóm | `YaruBorderContainer` / `YaruSection` | Có sẵn |

Ghi chú: DND chips chỉ **enable khi switch DND bật** (giống mockup: switch off → chip mờ).

---

## 3. Màn Settings (`02-settings.png`)

Bố cục 2 cột, nhóm theo section: GENERAL · DISPLAY · NOTIFICATIONS · ACCOUNT & DEVICE · SUPPORT.

```
Settings
Configure how NotifyTV behaves on your screen.

GENERAL                         DISPLAY
┌ Language        English(US) ┐  ┌ Appearance  [Dark][Light][Auto] ┐
│ Launch on Boot     [ ●──○ ] │  │ Overlay Opacity ──────●──  86%  │
└─────────────────────────────┘  └─────────────────────────────────┘

NOTIFICATIONS                                    Master Switch [●──○]
┌ Call Notifications [●] ┐ ┌ Alert Sound        ┐ ┌ Anchor Position ┐
│ Text Messages     [●] │ │  [Standard Ping ▾]  │ │  ▢ ▢            │
│ Image Previews    [●] │ │ Display Dur ──●  7s │ │  ▣ ▢            │
└───────────────────────┘ └────────────────────┘ │  ▢ ▢            │
                                                  └─────────────────┘
ACCOUNT & DEVICE                 SUPPORT
┌ 👤 admin@notifytv.com       ┐  ┌ Setup Guide          › ┐
│    Premium · [Sign Out][Mng]│  │ FAQs                 › │
│ Cloud Sync [●]   v4.2.0     │  │ Contact Support      › │
└─────────────────────────────┘  └────────────────────────┘
```

| Thành phần | Widget | Loại |
|-----------|--------|------|
| Tiêu đề section (GENERAL…) | `YaruSection(headline: Text(...))` | Có sẵn |
| Language (tile + giá trị phải) | `YaruTile(title, trailing: Text('English (US)'))` hoặc `ListTile` | Có sẵn |
| Launch on Boot / Cloud Sync | `YaruSwitchListTile` | Có sẵn |
| Appearance Dark/Light/Auto | `SegmentedButton<ThemeMode>` (Material) **hoặc** `YaruChoiceChipBar` | Có sẵn |
| Overlay Opacity / Display Duration | `YaruSlider` (label 86% / 7s qua callback) | Có sẵn |
| Master Switch (đầu section) | `YaruSwitch` trong `Row` với `_PageHeader` con | Có sẵn |
| Alert Sound (chọn 1 trong nhiều) | `YaruPopupMenuButton` hoặc `DropdownMenu` (Material) | Có sẵn |
| **Anchor Position** (lưới 2×3 chọn góc hiện toast) | **`AnchorPositionPicker`** (`GridView`/`Table` các `YaruSelectableContainer`, 1 ô selected) | Tạo mới |
| Ô "Đã chọn" trong lưới anchor | `YaruSelectableContainer(selected: …)` | Có sẵn |
| Profile account | `YaruTile(leading: CircleAvatar, title, subtitle, trailing: Row[buttons])` | Có sẵn |
| Sign Out / Manage Account | `OutlinedButton` / `FilledButton` (Material) | Có sẵn |
| Version | `YaruTile(trailing: Text('v4.2.0-stable'))` | Có sẵn |
| SUPPORT (item có chevron ›) | `YaruTile(trailing: Icon(YaruIcons.pan_end), onTap)` | Có sẵn |

> File Settings sẽ dài → tách `part`: `settings_general.dart`, `settings_notifications.dart`,
> `settings_account.dart`, `settings_support.dart` (tất cả `part of` màn Settings).

---

## 4. Màn Notification History (`03-notification-history.png`)

```
History                                              [ ⌫ Clear All ]
Review recent alerts from your connected devices.

┌───────────────────────────────────────────────── selected ──┐
│ 📱 iPhone 15 Pro  [MESSENGER]                    2 minutes ago │
│ Sarah Jenkins                                                 │
│ "Hey! Are we still on for the movie night? ..."               │
└───────────────────────────────────────────────────────────────┘
┌───────────────────────────────────────────────────────────────┐
│ 📱 Pixel 8  [GMAIL]                             15 minutes ago  │
│ Travel Alert: Delta Airlines                                    │
│ Your flight DL142 to Seattle ...                                │
└─────────────────────────────────────────────────────────────────┘
… (danh sách cuộn)
```

| Thành phần | Widget | Loại |
|-----------|--------|------|
| Nút "Clear All" (góc phải header) | `OutlinedButton.icon` (Material) — đặt trong `_PageHeader(trailing:)` | Có sẵn |
| Danh sách cuộn | `ListView.separated` + `Column(spacing:)` | Có sẵn |
| **Thẻ 1 notification** | **`NotificationHistoryTile`** dựng trên `YaruBanner`/`YaruSelectableContainer` | Tạo mới |
| Badge tên app (MESSENGER…) | `YaruInfoBadge` hoặc `Chip` (Material) | Có sẵn |
| Icon thiết bị + tên | `Row(spacing:)` [`Icon`, `Text`] | Có sẵn |
| Timestamp phải | `Text` (dùng `textTheme.labelSmall`) | Có sẵn |
| Trạng thái "được chọn" | `YaruSelectableContainer(selected: true)` (viền accent) | Có sẵn |

> Rỗng danh sách → dùng empty-state: `Column` [`Icon`, `Text`] căn giữa (có thể tạo `_EmptyState` shared).

---

## 5. Màn Manage Devices (`07-manage-devices.png`)

```
Manage Devices
Control and monitor your connected mobile devices.

┌ 📱 iPhone 15 Pro   ● Connected ┐ ┌ 📱 Galaxy Tab S9  ● Offline ┐
│    Last synced: Just now       │ │    Last synced: 2 days ago  │
│    [Rename] [🗑 Remove]        │ │    [Rename] [🗑 Remove]     │
└────────────────────────────────┘ └─────────────────────────────┘
┌ 📱 Pixel 8 Pro     ● Connected ┐ ┌ - - - - - - - - - - - - - - ┐
│    Last synced: 1 hour ago     │ ┊            +               ┊
│    [Rename] [🗑 Remove]        │ ┊     Add device via QR      ┊
└────────────────────────────────┘ └ - - - - - - - - - - - - - - ┘

┌────────────── banner ──────────────────────────────────────┐
│ Need to connect another device?              [⧉ Pair New]   │
│ Sync your phone or tablet instantly ...                     │
└──────────────────────────────────────────────────────────────┘
```

| Thành phần | Widget | Loại |
|-----------|--------|------|
| Lưới thẻ thiết bị | `GridView` / `Wrap(spacing:, runSpacing:)` | Có sẵn |
| **Thẻ thiết bị** | `paired_device_card.dart` (**đã có** trong `tv/lib/widgets/`) — bổ sung nút Rename/Remove nếu thiếu | Có sẵn (mở rộng) |
| Chấm trạng thái Connected/Offline | `_StatusDot` (§1) + `Text` | Tạo mới (dùng chung) |
| Rename / Remove | `OutlinedButton` / `OutlinedButton.icon` (Material) | Có sẵn |
| **Ô "Add device via QR" (viền đứt)** | **`_AddDeviceCard`** = `DottedBorder`? → tránh phụ thuộc; dùng `YaruBorderContainer` + `CustomPaint` viền đứt, hoặc `InkWell` bọc `Column[Icon(+), Text]` | Tạo mới |
| Banner "Need to connect…" | `YaruBanner` (title + subtitle + trailing button) | Có sẵn |
| Nút "Pair New Device" | `FilledButton.icon` (Material) | Có sẵn |

---

## 6. Màn Pair Device (`08-pair-device.png`)

```
Pair Device
Connect your mobile device to receive notifications ...

┌──────── QR ────────┐   ┌──── MANUAL OPTION ────────────┐
│  Scan to Pair       │   │ Pairing Code                  │
│  ┌─────────────┐    │   │ Having trouble? Enter code:   │
│  │ ▪▪ QR CODE ▪▪│    │   │   ┌───────────────────────┐   │
│  │ ▪▪▪▪▪▪▪▪▪▪▪▪│    │   │   │      A7 - 9B2         │   │
│  └─────────────┘    │   │   └───────────────────────┘   │
│  Scan this code     │   │      [ ⟳ Generate New Code ]  │
│  with your phone    │   ├───────────────────────────────┤
│                     │   │ ? Need help? Visit .../pair   │
└─────────────────────┘   └───────────────────────────────┘
```

| Thành phần | Widget | Loại |
|-----------|--------|------|
| 2 cột (QR / Manual) | `Row(spacing:)` + `Expanded` | Có sẵn |
| Thẻ chứa QR | `YaruBorderContainer` / `YaruSection` | Có sẵn |
| **Ảnh QR code** | `QrImageView` (package `qr_flutter`, đã thêm vào `tv/pubspec.yaml`) bọc trong **`_QrCard`** | Tạo mới |
| Nhãn "MANUAL OPTION" | `YaruInfoBadge` / `Text` (labelSmall) | Có sẵn |
| **Ô mã ghép "A7-9B2"** | **`PairingCodeDisplay`** = `Row` các ô ký tự (`YaruBorderContainer` mỗi ký tự) | Tạo mới |
| Generate New Code | `OutlinedButton.icon` (Material) | Có sẵn |
| Footer trợ giúp | `YaruTile(leading: Icon, title, subtitle)` | Có sẵn |

---

## 7. Toast overlay (3 màn: Voice call / Video call / Text message)

3 màn `04/05/06` là **overlay `SYSTEM_ALERT_WINDOW`** hiện góc màn (theo Anchor Position ở Settings),
không nằm trong nav-rail. Cùng một khung chung, chỉ khác nội dung + nút hành động.

```
┌──────── Toast (góc trên phải) ─────────┐
│ [icon] MESSENGER / INCOMING CALL   ⏱   │  ← header: badge app + timestamp/label
│ ┌───┐ Tên người gửi                    │
│ │👤 │ dòng phụ (Mobile / WhatsApp…)     │
│ └───┘ nội dung / message …             │
│ ┌─────────────┐ ┌─────────────┐        │
│ │ [PRIMARY]   │ │ [SECONDARY] │        │  ← Accept/Answer/Read More  +  Decline/Dismiss
│ └─────────────┘ └─────────────┘        │
│  ⌨ TO CLOSE      ⌨ TO VIEW             │  ← gợi ý phím (chỉ màn message)
└─────────────────────────────────────────┘
```

| Biến thể | PRIMARY | SECONDARY | Header label |
|----------|---------|-----------|--------------|
| Voice call (`04`) | Accept (icon phone) | Decline | INCOMING CALL |
| Video call (`05`) | Answer (icon video) | Dismiss | INCOMING VIDEO CALL |
| Text message (`06`) | Read More | Dismiss | \<APP\> + "Just now" |

| Thành phần | Widget | Loại |
|-----------|--------|------|
| **Khung toast chung** | **`NotificationToast({header, avatar, title, subtitle, body, primaryAction, secondaryAction, remoteHints})`** | Tạo mới |
| Nền/khung bo | `YaruBorderContainer` (bo góc, elevation từ theme) | Có sẵn |
| Badge app + label | `Row(spacing:)` [`Icon`/`YaruInfoBadge`, `Text`] | Có sẵn |
| Avatar | `CircleAvatar` (Material) | Có sẵn |
| Nút primary | `FilledButton.icon` (Material) | Có sẵn |
| Nút secondary | `OutlinedButton.icon` / `TextButton` (Material) | Có sẵn |
| Gợi ý phím TO CLOSE/TO VIEW | **`_RemoteKeyHint`** (`Row` [icon phím, `Text`]) | Tạo mới |
| Animation vào/ra | `tv_main_screen_notifications.dart` (**đã có** overlay animation) | Có sẵn |

> TV app đã có `overlay_service.dart` + `tv_main_screen_notifications.dart`; `NotificationToast`
> là widget hiển thị bên trong overlay đó — tách theo biến thể bằng enum `ToastKind { voiceCall, videoCall, message }`.

---

## 8. Tổng hợp widget cần TẠO MỚI

Ưu tiên đặt widget dùng chung ở `shared`, widget riêng TV ở `tv/lib/widgets/`.

| Widget | Vị trí đề xuất | Dùng ở màn |
|--------|----------------|-----------|
| `_AppRailHeader`, `_RailDeviceFooter` | `tv/lib/widgets/app_rail.dart` | Tất cả full-page |
| `_StatusDot` | `shared` (dùng cả phone) | Rail, Manage Devices |
| `_PageHeader` | `tv/lib/widgets/page_header.dart` | Tất cả full-page |
| `_HomeActionCard` | `tv/lib/widgets/home_action_card.dart` | Home |
| `AnchorPositionPicker` | `tv/lib/widgets/anchor_position_picker.dart` | Settings |
| `NotificationHistoryTile` | `tv/lib/widgets/notification_history_tile.dart` | History |
| `_AddDeviceCard` | `tv/lib/widgets/add_device_card.dart` | Manage Devices |
| `_QrCard` | `tv/lib/widgets/qr_card.dart` (cần dep `qr_flutter`) | Pair Device |
| `PairingCodeDisplay` | `shared` (phone cũng nhập/hiện mã) | Pair Device |
| `NotificationToast` (+ `_RemoteKeyHint`, enum `ToastKind`) | `tv/lib/widgets/notification_toast.dart` | 3 màn toast |
| `_EmptyState` (tuỳ chọn) | `shared` | History rỗng |

**Dependency phát sinh**: `qr_flutter: ^4.1.0` — đã thêm vào `tv/pubspec.yaml` (`fvm flutter pub get` chạy OK).

> **Lệch với pairing hiện tại**: `server_service.dart` hiện chỉ sinh **PIN số 4 chữ số**
> (`/api/pair` → `_currentPin`), không có luồng mã hoá QR. Mockup vẽ QR + mã chữ-số 5 ký tự
> (`A7-9B2`) là **thiết kế tương lai**, cần thêm bước encode nội dung QR (vd. IP + token tạm)
> ở `server_service.dart` và **scan QR ở phone** (thêm package quét, vd. `mobile_scanner`, chưa
> có trong `phone/pubspec.yaml`). Trước mắt dựng UI với `QrImageView` nhận `data` truyền vào,
> còn logic sinh nội dung QR thật để làm ở task riêng.

---

## 9. Ánh xạ điều hướng ↔ code hiện có

| Mục rail | Trạng thái code |
|----------|-----------------|
| Home | Tạo mới nội dung §2 |
| History | `tv_main_screen_*` đã có history/clear → gắn `NotificationHistoryTile` |
| Manage Devices | `paired_device_card.dart` đã có → thêm lưới + `_AddDeviceCard` + banner |
| Pair Device | Ghép với `server_service.dart` PIN pairing (§6) |
| Setup Guide | Chưa có — trang tĩnh, làm sau |
| Settings | Có DND/permission sẵn trong panels → mở rộng theo §3 |

> **Quyết định phạm vi**: giữ **ACCOUNT & DEVICE** (email/Premium/Sign Out/Manage Account/Cloud Sync)
> và **Language** dạng **stub hiển thị** trong Settings — dựng đúng layout mockup (`YaruTile`,
> `YaruSwitchListTile`...) nhưng **vô hiệu hoá tương tác** (`onTap: null` / nút `enabled: false`)
> vì app hiện là P2P local, chưa có backend account/cloud. Không xoá khỏi UI để giữ đúng bố cục
> tổng thể Settings; khi có backend thật chỉ cần nối lại logic, không phải vẽ lại layout.
> Version (`v4.2.0-stable`) đọc từ `package_info_plus` — **hoạt động thật**, không phải stub.

---

## 10. Implementation cuối cùng (đã hoàn thành) — điểm lệch so với §1-9

Toàn bộ refactor đã triển khai và verify trực tiếp trên `emulator-5556` (Television_1080p AVD).
Mục này ghi lại các quyết định/điều chỉnh thực tế trong lúc code, khác với kế hoạch ban đầu ở §1-9.

### 10.1 Phạm vi cuối cùng
- **Setup Guide bị loại khỏi nav rail** (quyết định trước khi code) — rail chỉ còn **5 mục**:
  Home, History, Manage Devices, Pair Device, Settings. Card "Setup Guide" ở Home (§2) được thay
  bằng card **"Manage Devices"** (điều hướng tới trang Manage Devices) thay vì trỏ tới trang không
  tồn tại.
- **Settings không phải stub** — toàn bộ mục (trừ Account/Language/Cloud Sync/Support — giữ đúng
  quyết định stub ở trên) có **logic thật**: Theme mode, Overlay Opacity, Anchor Position, Display
  Duration, Alert Sound, Launch on Boot, Call/Text/Image Previews toggle đều ghi xuống
  `TvSettingsService` (SharedPreferences) và có hiệu lực thật trên overlay/behavior.
- **Toast overlay (§7) đã redesign đầy đủ ở phía native Kotlin** (không phải Flutter widget —
  overlay thật là 1 `View` do `MainActivity.kt` vẽ qua `WindowManager`, xem 10.4).

### 10.2 Khung điều hướng (§1) — thực tế
- `SizedBox(width: 250, child: YaruNavigationRail(...))` — **bắt buộc phải bọc `SizedBox`**:
  đặt `YaruNavigationRail` trực tiếp trong `Row` không có `Expanded` khiến nó nhận constraint
  chiều rộng vô hạn từ `Row`, gây `TransformLayer is constructed with an invalid matrix` và toàn
  bộ trang bên phải render sai vị trí (đè lên rail). Bài học: mọi widget dùng `YaruNavigationRail`
  trong `Row` phải có `SizedBox`/`ConstrainedBox` bao ngoài.
- Widget thực tế là **public class** (không phải `_Foo` private) vì cần import chéo file/package:
  `AppRailHeader`, `RailDeviceFooter` (`tv/lib/widgets/app_rail.dart`), `PageHeader`
  (`tv/lib/widgets/page_header.dart`), `StatusDot` (`shared/lib/widgets/status_dot.dart`).
- Điều hướng dùng provider Riverpod `tvNavIndexProvider` (`tv/lib/providers/tv_nav_provider.dart`,
  enum `TvNavPage`), không dùng `Navigator`/route — chuyển trang chỉ là đổi `state` + `switch` chọn
  widget trang tương ứng trong `TvMainScreen._buildPage`.
- Rail footer đọc `Platform.operatingSystemVersion` (không có device_info_plus mới), chỉ mang tính
  trang trí.

### 10.3 Bug quan trọng phát hiện khi code: `YaruBanner` ép `height: double.infinity`
`YaruBanner`/`YaruBanner.tile` luôn bọc `Container(width: double.infinity, height: double.infinity)`
bên trong — **bắt buộc phải có ancestor giới hạn chiều cao** (`SizedBox`, ô `GridView` có
`mainAxisExtent`...). Dùng trực tiếp trong `Row`/`Column` không giới hạn chiều cao (vd. `Expanded`
trong 1 `Row` thường, hoặc item của `ListView` không fixed-height) khiến `RenderBox` có size vô hạn,
im lặng vỡ layer khi paint (không throw exception Dart, không có overflow banner — chỉ render sai
vị trí/biến mất). Đã sửa bằng cách:
- `_HomeActionCard` (Home) và banner "Need to connect..." (Manage Devices): bọc
  `SizedBox(height: 96, child: YaruBanner.tile(...))`.
- `NotificationHistoryTile` (History, dùng trong `ListView.separated` — chiều cao thay đổi theo nội
  dung nên không thể fix cứng): **đổi hẳn sang `Card` + `Padding`** thay vì `YaruBanner`.

### 10.4 Toast overlay — native Kotlin (thay thế toàn bộ §7)
Widget `NotificationToast`/`ToastKind` trong kế hoạch cũ **không tồn tại** — toast thật vẽ bởi
`MainActivity.kt` qua `WindowManager.addView` (native Android View, ngoài widget tree Flutter),
layout ở `tv/android/app/src/main/res/layout/notification_overlay_layout.xml`. Chi tiết:

- **Phân loại (`category`)**: heuristic ở `MyNotificationListener.kt` (phone) đọc
  `Notification.category` (`CATEGORY_CALL`/`CATEGORY_MESSAGE`) + từ khoá "video" trong title/text
  → 1 trong 4 giá trị `voice_call` / `video_call` / `message` / `generic`
  (`NotificationCategory` enum, `shared/lib/models/notification_category.dart`), xuyên suốt
  `NotificationItem` → WebSocket → `server_service.dart` → `background_service.dart` →
  `OverlayService.showOverlay(category:)` → `MainActivity.kt`.
- **1 layout thích ứng duy nhất** (không tách 3 file XML) — ẩn/hiện theo category:
  `headerLabel`/`timeGroup` (call: "INCOMING CALL"/"INCOMING VIDEO CALL", ẩn giờ; message/generic:
  "$appName • Just now"), avatar 56dp tái dùng `appIcon` sẵn có (fallback `ic_person_placeholder`
  cho call/message, `ic_notification_bell` cho generic — **không có field avatar riêng**, đúng như
  quyết định gốc), `actionRow` (2 nút, `GONE` cho generic), `remoteHintRow` ("⌨ TO CLOSE"/"⌨ TO VIEW",
  chỉ hiện ở message — **text tĩnh trang trí, không xử lý phím remote thật**).
- **Nút hành động chỉ dismiss** (`hideNotificationOverlay()`), không relay hành động thật về phone —
  đúng quyết định đã chốt.
- Bỏ `FLAG_NOT_TOUCHABLE` (giữ `FLAG_NOT_FOCUSABLE` + `FLAG_KEEP_SCREEN_ON`) để nút bấm được bằng
  chuột/touch; **giới hạn đã biết**: chưa hỗ trợ bấm bằng D-pad remote thật.
- **Overlay Opacity thật**: `buildOverlayBackground(opacity)` dựng `GradientDrawable` runtime thay
  cho `overlay_background.xml` tĩnh (đã xoá file này).
- **Alert Sound thật**: `pickAlertSound()` mở `RingtoneManager.ACTION_RINGTONE_PICKER` qua
  `startActivityForResult` + `onActivityResult` (kết quả bất đồng bộ, lưu tạm
  `pendingAlertSoundResult`); phát bằng `RingtoneManager.getRingtone(...).play()` khi show overlay.
  **Lưu ý bug đã sửa**: phải phân biệt `resultCode == RESULT_OK` (chọn Silent thật) với
  `RESULT_CANCELED`/không có app xử lý (giữ nguyên setting cũ) — ban đầu code coi mọi URI null là
  "Silent", sai khi người dùng chỉ huỷ picker.
- **Launch on Boot thật**: `BootReceiver.kt` đọc trực tiếp Android `SharedPreferences` file
  `FlutterSharedPreferences`, key `flutter.tv_launch_on_boot` (quy ước của plugin
  `shared_preferences`), bỏ qua start service nếu `false`.
- **Anchor Position**: `AnchorPositionPicker` là lưới **2×2** (không phải 2×3 như mockup — chỉ 4 vị
  trí góc thật tồn tại trong `MirrorProtocol`), TV **override** hoàn toàn giá trị phone gửi kèm
  (`overlayPosition`/`overlayDuration`) bằng `TvSettings` cục bộ trong
  `background_service.dart::onStart` — vì TV là màn hình hiển thị nên tự quyết định vị trí/thời
  lượng, không phụ thuộc phone.
- **Lọc theo loại + ẩn ảnh**: `server_service.dart._handleNewNotification` chặn hoàn toàn (không
  lưu history, không phát overlay) nếu `callNotificationsEnabled`/`textNotificationsEnabled` tắt
  đúng category; xoá `appIcon` nếu `imagePreviewsEnabled` tắt.
- **DND theo thời lượng** (chip 1 Hour/6 Hours/Until Tomorrow ở Home): **không gate theo switch
  DND** như dự kiến ban đầu — chip luôn bấm được, gọi thẳng `setDndForDuration(Duration)` (bật DND
  có hạn, tự tắt khi hết giờ qua `ServerService.checkDndExpiry()` chạy mỗi giây trong
  `background_service.dart`). Switch "Do Not Disturb"/"Notification Receiving" là bật/tắt vô hạn
  (`toggleDndIndefinite()`), độc lập với chip.

### 10.5 AppToast cho TV
Đã thêm `AppToast`/`ToastData` vào `tv/lib/providers/tv_providers.dart` (mirror pattern từ
`phone/lib/providers/phone_providers.dart`) + 1 `ref.listen` duy nhất ở `TvMainScreen.build()` hiển
thị qua `ScaffoldMessenger` — đúng rule CLAUDE.md, trước đó TV **chưa có** cơ chế này.

### 10.6 Dependency mới đã thêm
`qr_flutter: ^4.1.0` (Pair Device), `package_info_plus: ^8.1.2` (Version thật ở Settings) — cả hai
trong `tv/pubspec.yaml`.

### 10.7 File cũ đã xoá (thay thế hoàn toàn bởi kiến trúc nav rail)
`tv/lib/screens/tv_main_screen_panels.dart`, `tv/lib/screens/tv_main_screen_notifications.dart`,
`tv/lib/widgets/status_info_boxes.dart`, `tv/lib/widgets/tv_button.dart`,
`tv/android/.../res/drawable/overlay_background.xml`.
