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

  // ── Notification handling ─────────────────────────────────────────────────

  void _handleNewNotification(NotificationItem item) async {
    // 1. Blocked keywords
    final blockedKw = MirrorFilterEvaluator.findMatchingBlockedKeyword(
      item.title,
      item.text,
      _settings.blockedKeywords,
    );
    if (blockedKw != null) {
      debugPrint("Notification blocked by keyword '$blockedKw': ${item.title}");
      return;
    }

    // 2. Quiet hours
    if (_settings.quietHoursEnabled &&
        MirrorFilterEvaluator.isTimeInQuietHours(
          _settings.quietHoursStart,
          _settings.quietHoursEnd,
          DateTime.now(),
        )) {
      debugPrint(
          "Notification blocked by Quiet Hours schedule: ${item.title}");
      return;
    }

    // 3. Dynamically register new apps
    if (!_appFilters.containsKey(item.packageName)) {
      await _saveFilter(item.packageName, true);
    }

    // 4. Per-app filter
    if (!(_appFilters[item.packageName] ?? true)) {
      debugPrint("Notification from ${item.packageName} filtered out.");
      return;
    }

    // 5. Add to history
    if (mounted) {
      setState(() {
        _history.insert(0, item);
        if (_history.length > 50) _history.removeLast();
      });
    }

    // 6. Fetch icon
    final pkg = item.packageName;
    if (!_appIconCache.containsKey(pkg)) {
      try {
        final appInfo = await InstalledApps.getAppInfo(pkg);
        _appIconCache[pkg] = appInfo?.icon;
        if (mounted) setState(() {});
      } catch (_) {}
    }

    // 7. Fast-reconnect if offline
    if (!_isConnected) {
      debugPrint(
          "Notification received while offline. Attempting fast reconnect...");
      await _connector.connectToSavedTv();
      if (mounted) setState(() => _isConnected = _connector.isConnected);
    }

    // 8. Send to TV
    if (_isConnected) {
      final iconBytes = _appIconCache[pkg];
      final base64Icon = iconBytes != null ? base64Encode(iconBytes) : null;
      _connector.sendNotification(
        item,
        base64Icon: base64Icon,
        overlayPosition: _settings.overlayPosition,
        overlayDurationMs: _settings.overlayDurationSeconds * 1000,
      );
    } else {
      debugPrint("Failed to send notification to TV: Connection is offline.");
    }
  }

  void _sendTestNotification() {
    final testItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: 'com.dyno.tv_notification_mirror.phone',
      appName: 'TV Mirror',
      title: 'Jane Doe',
      text: 'Hello from your TV Mirror app! 📺✨',
      postTime: DateTime.now().millisecondsSinceEpoch,
    );
    _handleNewNotification(testItem);
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showPairingDialog(TVDevice device) async {
    final success = await _connector.startPairing(device);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to connect to TV. Make sure the TV app is open.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YaruDialogTitleBar(
                    title: Text('Pair with ${device.name}'),
                    isClosable: !isLoading,
                    onClose: (_) => Navigator.pop(dialogCtx),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading) ...[
                          const YaruCircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text(
                            'Connecting...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ] else ...[
                          const Text(
                            'Enter the 4-digit PIN displayed on your TV screen:',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: pinController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(),
                              hintText: '0000',
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (!isLoading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              YaruOptionButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              YaruOptionButton(
                                onPressed: () async {
                                  final pin = pinController.text.trim();
                                  if (pin.length == 4) {
                                    setDialogState(() => isLoading = true);
                                    final isPaired = await _connector
                                        .confirmPairing(device, pin);
                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isPaired
                                                ? 'Successfully paired with ${device.name}!'
                                                : 'Incorrect PIN. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Pair'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManualConnectDialog() {
    final ipController = TextEditingController(text: '10.0.2.2');
    final portController = TextEditingController(text: '8080');

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              YaruDialogTitleBar(
                title: const Text('Connect with IP'),
                onClose: (_) => Navigator.pop(dialogCtx),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    YaruSearchField(
                      controller: ipController,
                      autofocus: true,
                      hintText: 'TV IP Address (e.g. 192.168.1.50)',
                    ),
                    const SizedBox(height: 12),
                    YaruSearchField(
                      controller: portController,
                      hintText: 'Port (e.g. 8080)',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        YaruOptionButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        YaruOptionButton(
                          onPressed: () {
                            final ip = ipController.text.trim();
                            final port =
                                int.tryParse(portController.text.trim()) ??
                                    8080;
                            if (ip.isNotEmpty) {
                              Navigator.pop(dialogCtx);
                              _showPairingDialog(
                                  TVDevice(name: 'Manual TV', ip: ip, port: port));
                            }
                          },
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCustomAppDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            YaruDialogTitleBar(
              title: const Text('Add Custom App Filter'),
              onClose: (_) => Navigator.pop(dialogCtx),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YaruSearchField(
                    controller: controller,
                    autofocus: true,
                    hintText: 'App package name (e.g. com.spotify.music)',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      YaruOptionButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      YaruOptionButton(
                        onPressed: () {
                          final pkg = controller.text.trim();
                          if (pkg.isNotEmpty) {
                            _saveFilter(pkg, true);
                            Navigator.pop(dialogCtx);
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Tab items metadata
    final navItems = [
      (icon: YaruIcons.computer, label: 'Connect'),
      (icon: YaruIcons.pen, label: 'Apps'),
      (icon: YaruIcons.history, label: 'History'),
    ];

    Widget buildPage(int index) {
      if (!_hasPermission) {
        return Column(
          children: [
            PermissionBanner(notifier: _notifier),
            Expanded(child: _buildTab(index)),
          ],
        );
      }
      return _buildTab(index);
    }

    return YaruNavigationPage(
      length: navItems.length,
      initialIndex: _currentIndex,
      onSelected: (i) => setState(() => _currentIndex = i),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: YaruIconButton(
          icon: const Icon(YaruIcons.refresh),
          onPressed: () {
            _checkPermission();
            _connector.startScanning();
          },
          tooltip: 'Refresh / Scan',
        ),
      ),
      itemBuilder: (context, index, selected) => YaruNavigationRailItem(
        icon: Icon(navItems[index].icon),
        label: Text(navItems[index].label),
        style: YaruNavigationRailStyle.labelledExtended,
        selected: selected,
      ),
      pageBuilder: (context, index) => buildPage(index),
    );
  }

  Widget _buildTab(int index) {
    return switch (index) {
      0 => ConnectTab(
          isConnected: _isConnected,
          discoveredDevices: _discoveredDevices,
          connectedTvName: _connector.connectedTvName,
          tvDndEnabled: _settings.tvDndEnabled,
          settings: _settings,
          connector: _connector,
          onSendTest: _sendTestNotification,
          onManualConnect: _showManualConnectDialog,
          onDndChanged: _onDndChanged,
          onPairDevice: _showPairingDialog,
        ),
      1 => FiltersTab(
          settings: _settings,
          appFilters: _appFilters,
          installedPresets: _installedPresets,
          iconCache: _appIconCache,
          onSettingsChanged: _onSettingsChanged,
          onFilterChanged: _saveFilter,
          onAddCustomApp: _showAddCustomAppDialog,
        ),
      _ => HistoryTab(
          history: _history,
          iconCache: _appIconCache,
        ),
    };
  }
}
