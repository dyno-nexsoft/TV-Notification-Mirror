# State Management Architecture — TV Notification Mirror

Tài liệu này mô tả chi tiết kiến trúc và cách tổ chức quản lý trạng thái (State Management) trong ứng dụng **TV Notification Mirror** bằng thư viện **Flutter Riverpod** (`flutter_riverpod`).

---

## 1. Nguyên tắc quản lý trạng thái (Core Principles)

1. **Phân tách trách nhiệm (Separation of Concerns):**
   - **UI (Screens & Widgets):** Chỉ đảm nhận nhiệm vụ hiển thị giao diện, không giữ trạng thái nghiệp vụ phức tạp. UI lắng nghe trực tiếp từ Riverpod Providers.
   - **Services (`ConnectorService`, `NotificationService`, `OverlayService`, `ServerService`):** Đảm nhận giao tiếp native, WebSocket, storage, và mDNS.
   - **Providers:** Là cầu nối trung gian giữa Services và UI, chịu trách nhiệm quản lý state, lắng nghe các luồng dữ liệu (Streams), và cung cấp API để UI tương tác.

2. **Khái niệm Riverpod Providers:**
   - **`Notifier` / `AsyncNotifier`:** Quản lý trạng thái đồng bộ hoặc bất đồng bộ có thể thay đổi (Mutable state with actions).
   - **`StreamProvider` / `FutureProvider`:** Chuyển đổi các Luồng sự kiện (Stream) hoặc Tải dữ liệu bất đồng bộ (Future) thành trạng thái UI phản ứng (Reactive state).
   - **`Provider`:** Cung cấp các service instance hoặc giá trị được tính toán (computed state).

3. **Tránh Prop-Drilling:**
   - Các private widget UI (`_MainScreenBody`, `ConnectTab`, `_LeftControlPanel`, v.v.) kế thừa `ConsumerWidget` hoặc `ConsumerStatefulWidget` để đọc state trực tiếp thông qua `ref.watch()` / `ref.read()`.

---

## 2. Cấu trúc State ở Ứng dụng Phone (`phone/`)

Mã nguồn được đặt tại `phone/lib/providers/phone_providers.dart`.

### Các Provider chính:

- **`phonePermissionProvider`:**
  - Loại: `Notifier<bool>`
  - Vai trò: Kiểm tra và theo dõi quyền đọc thông báo Android (`NotificationService.checkPermission()`).

- **`phoneConnectorProvider`:**
  - Loại: `Notifier<PhoneConnectorState>`
  - Vai trò: Quản lý danh sách thiết bị TV quét được qua mDNS (`_discoveredDevices`), trạng thái kết nối WebSocket (`_isConnected`), và tên TV đang kết nối (`_connectedTvName`). Cung cấp các hành động: `startScanning()`, `stopScanning()`, `connectToDevice()`, `pairDevice()`, `sendTestNotification()`.

- **`phoneSettingsProvider`:**
  - Loại: `Notifier<AppSettings>`
  - Vai trò: Tải và lưu cài đặt khung giờ yên tĩnh, từ khóa chặn, thời gian hiển thị overlay, và chế độ TV DND qua `FilterService`.

- **`phoneFiltersProvider`:**
  - Loại: `Notifier<PhoneFiltersState>`
  - Vai trò: Quản lý danh sách ứng dụng đã cài đặt (`installedPresets`), bộ nhớ đệm icon (`iconCache`), và trạng thái lọc ứng dụng (`appFilters`).

- **`phoneHistoryProvider`:**
  - Loại: `Notifier<List<NotificationItem>>`
  - Vai trò: Theo dõi lịch sử thông báo đã bắt được trên điện thoại và gửi sang TV.

---

## 3. Cấu trúc State ở Ứng dụng TV (`tv/`)

Mã nguồn được đặt tại `tv/lib/providers/tv_providers.dart`.

### Các Provider chính:

- **`tvPermissionsProvider`:**
  - Loại: `Notifier<TvPermissionsState>`
  - Vai trò: Theo dõi quyền `SYSTEM_ALERT_WINDOW` (Overlay) và `POST_NOTIFICATIONS` trên TV.

- **`tvIpProvider`:**
  - Loại: `FutureProvider<String>`
  - Vai trò: Lấy địa chỉ IP IPv4 nội bộ của TV để hiển thị lên bảng điều khiển.

- **`tvServiceStateProvider`:**
  - Loại: `StreamProvider<TvServiceData>`
  - Vai trò: Lắng nghe sự kiện `stateUpdate` từ `FlutterBackgroundService`, tự động cập nhật mã PIN ghép đôi, trạng thái FGS service, trạng thái DND, danh sách thiết bị đã ghép đôi (`pairedClients`), và lịch sử thông báo nhận được.

---

## 4. Hướng dẫn sử dụng cho Developer

1. **Khởi tạo Root App:**
   Bọc `MyApp` bằng `ProviderScope`:
   ```dart
   void main() {
     runApp(
       const ProviderScope(
         child: MyApp(),
       ),
     );
   }
   ```

2. **Đọc và thay đổi State trong Widget:**
   ```dart
   class MyWidget extends ConsumerWidget {
     const MyWidget({super.key});

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final isConnected = ref.watch(phoneConnectorProvider.select((s) => s.isConnected));
       
       return ElevatedButton(
         onPressed: () => ref.read(phoneConnectorProvider.notifier).startScanning(),
         child: Text(isConnected ? 'Connected' : 'Scan'),
       );
     }
   }
   ```
