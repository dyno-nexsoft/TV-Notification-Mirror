import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:shared/shared.dart';

import '../services/connector_service.dart';
import '../services/filter_service.dart';
import '../services/notification_service.dart';
import '../widgets/permission_banner.dart';
import '../widgets/connect/connect_tab.dart';
import '../widgets/filters/filters_tab.dart';
import '../widgets/history/history_tab.dart';

part 'main_screen_dialogs.dart';
part 'main_screen_dialog_launchers.dart';
part 'main_screen_notifications.dart';
part 'main_screen_body.dart';

/// The root screen of the phone app. Handles only:
/// - Tab navigation
/// - Stream subscriptions (devices, connection state, notifications)
/// - App lifecycle observation
/// Delegates all business logic to [FilterService] and [ConnectorService].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _connector = ConnectorService();
  final _notifier = NotificationService();

  bool _hasPermission = false;
  bool _isConnected = false;

  List<TVDevice> _discoveredDevices = [];
  final List<NotificationItem> _history = [];
  Map<String, bool> _appFilters = {};
  final Map<String, Uint8List?> _appIconCache = {};
  List<Map<String, dynamic>> _installedPresets = [];

  AppSettings _settings = const AppSettings(
    quietHoursEnabled: false,
    quietHoursStart: TimeOfDay(hour: 22, minute: 0),
    quietHoursEnd: TimeOfDay(hour: 7, minute: 0),
    blockedKeywords: [],
    overlayPosition: 'top_right',
    overlayDurationSeconds: 5,
    tvDndEnabled: false,
  );

  StreamSubscription<List<TVDevice>>? _deviceSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<NotificationItem>? _notificationSub;
  StreamSubscription<String>? _removedSub;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _loadAll();
    _isConnected = _connector.isConnected;

    _deviceSub = _connector.devicesStream.listen((devices) {
      setState(() => _discoveredDevices = devices);
    });

    _connectionSub = _connector.connectionStateStream.listen((state) {
      setState(() => _isConnected = state);
    });

    _notificationSub = _notifier.notificationStream.listen(_handleNewNotification);

    _removedSub = _notifier.notificationRemovedStream.listen((id) {
      _connector.sendNotificationRemoved(id, '');
    });

    _connector.startScanning();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deviceSub?.cancel();
    _connectionSub?.cancel();
    _notificationSub?.cancel();
    _removedSub?.cancel();
    _connector.stopScanning();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([_loadFilters(), _loadSettings(), _loadInstalledApps()]);
  }

  Future<void> _checkPermission() async {
    final status = await _notifier.checkPermission();
    if (mounted) setState(() => _hasPermission = status);
  }

  Future<void> _loadFilters() async {
    final filters = await FilterService.loadFilters();
    if (mounted) setState(() => _appFilters = filters);
  }

  Future<void> _loadSettings() async {
    final settings = await FilterService.loadSettings();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _loadInstalledApps() async {
    try {
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );

      final loadedApps = <Map<String, dynamic>>[];
      for (final app in apps) {
        final pkg = app.packageName;
        if (app.icon != null) _appIconCache[pkg] = app.icon;
        loadedApps.add({
          'pkg': pkg,
          'name': app.name,
          'color': Colors.transparent,
        });
      }

      loadedApps.sort((a, b) =>
          (a['name'] as String).toLowerCase().compareTo(
                (b['name'] as String).toLowerCase(),
              ));

      if (mounted) setState(() => _installedPresets = loadedApps);
    } catch (e) {
      debugPrint('Failed to load installed apps: $e');
    }
  }

  // ── Filter / settings mutations ───────────────────────────────────────────

  Future<void> _saveFilter(String packageName, bool value) async {
    await FilterService.saveFilter(packageName, value);
    if (mounted) {
      setState(() => _appFilters = {..._appFilters, packageName: value});
    }
  }

  void _onSettingsChanged(AppSettings updated) {
    setState(() => _settings = updated);
  }

  Future<void> _onDndChanged(bool val) async {
    setState(() => _settings = _settings.copyWith(tvDndEnabled: val));
    _connector.sendDndToggle(val);
    await FilterService.saveTvDnd(val);
  }

  /// Thin `setState` forwarder callable from the [_NotificationHandling]
  /// extension, which cannot call the `@protected` `setState` directly.
  void _refresh(VoidCallback fn) => setState(fn);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _MainScreenBody(
      currentIndex: _currentIndex,
      hasPermission: _hasPermission,
      isConnected: _isConnected,
      discoveredDevices: _discoveredDevices,
      history: _history,
      appFilters: _appFilters,
      appIconCache: _appIconCache,
      installedPresets: _installedPresets,
      settings: _settings,
      connector: _connector,
      notifier: _notifier,
      onTabSelected: (i) => setState(() => _currentIndex = i),
      onRefresh: () {
        _checkPermission();
        _connector.startScanning();
      },
      onSendTest: _sendTestNotification,
      onManualConnect: _showManualConnectDialog,
      onDndChanged: _onDndChanged,
      onPairDevice: _showPairingDialog,
      onSettingsChanged: _onSettingsChanged,
      onFilterChanged: _saveFilter,
      onAddCustomApp: _showAddCustomAppDialog,
    );
  }
}
