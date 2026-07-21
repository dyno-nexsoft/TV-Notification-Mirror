import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'models/notification_item.dart';
import 'services/connector_service.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Notification Mirror',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7F5AF0),
          secondary: Color(0xFF2CB67D),
          surface: Color(0xFF16161A),
          error: Color(0xFFFF5252),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16161A),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
              if (states.contains(WidgetState.focused)) {
                return const BorderSide(color: Colors.white, width: 2.5);
              }
              return BorderSide.none;
            }),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
              if (states.contains(WidgetState.focused)) {
                return const BorderSide(color: Color(0xFF7F5AF0), width: 2.5);
              }
              return BorderSide.none;
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
              if (states.contains(WidgetState.focused)) {
                return const BorderSide(color: Colors.white, width: 2.5);
              }
              return null;
            }),
          ),
        ),
        fontFamily: 'Outfit', // A modern font family, falling back to system
      ),
      home: const MainScreen(),
    );
  }
}

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
  List<TVDevice> _discoveredDevices = [];
  bool _isConnected = false;
  List<NotificationItem> _history = [];
  Map<String, bool> _appFilters = {}; // packageName -> enabled
  final Map<String, Uint8List?> _appIconCache = {};
  String _filterSearchQuery = '';
  List<Map<String, dynamic>> _installedPresets = [];

  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);
  List<String> _blockedKeywords = [];
  String _overlayPosition = 'top_right';
  int _overlayDurationSeconds = 5;
  bool _tvDndEnabled = false;

  final TextEditingController _keywordController = TextEditingController();

  StreamSubscription? _deviceSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _notificationSub;
  StreamSubscription? _removedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _loadFilters();
    _loadSettings();
    _checkInstalledPresets();
    _isConnected = _connector.isConnected;

    // Listen to changes
    _deviceSub = _connector.devicesStream.listen((devices) {
      setState(() {
        _discoveredDevices = devices;
      });
    });

    _connectionSub = _connector.connectionStateStream.listen((state) {
      setState(() {
        _isConnected = state;
      });
    });

    _notificationSub = _notifier.notificationStream.listen((item) {
      _handleNewNotification(item);
    });

    _removedSub = _notifier.notificationRemovedStream.listen((id) {
      _connector.sendNotificationRemoved(id, '');
    });

    // Start mDNS scan immediately
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

  Future<void> _checkPermission() async {
    final status = await _notifier.checkPermission();
    setState(() {
      _hasPermission = status;
    });
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('filter_'));
    final Map<String, bool> filters = {};
    for (var key in keys) {
      final pkg = key.replaceFirst('filter_', '');
      filters[pkg] = prefs.getBool(key) ?? true;
    }
    setState(() {
      _appFilters = filters;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quietHoursEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      final startHour = prefs.getInt('quiet_hours_start_hour') ?? 22;
      final startMinute = prefs.getInt('quiet_hours_start_minute') ?? 0;
      _quietHoursStart = TimeOfDay(hour: startHour, minute: startMinute);

      final endHour = prefs.getInt('quiet_hours_end_hour') ?? 7;
      final endMinute = prefs.getInt('quiet_hours_end_minute') ?? 0;
      _quietHoursEnd = TimeOfDay(hour: endHour, minute: endMinute);

      _blockedKeywords = prefs.getStringList('blocked_keywords') ?? [];
      _overlayPosition = prefs.getString('overlay_position') ?? 'top_right';
      _overlayDurationSeconds = prefs.getInt('overlay_duration_seconds') ?? 5;
      _tvDndEnabled = prefs.getBool('tv_dnd_enabled') ?? false;
    });
  }

  Future<void> _saveQuietHours(bool enabled, TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quiet_hours_enabled', enabled);
    await prefs.setInt('quiet_hours_start_hour', start.hour);
    await prefs.setInt('quiet_hours_start_minute', start.minute);
    await prefs.setInt('quiet_hours_end_hour', end.hour);
    await prefs.setInt('quiet_hours_end_minute', end.minute);
    setState(() {
      _quietHoursEnabled = enabled;
      _quietHoursStart = start;
      _quietHoursEnd = end;
    });
  }

  Future<void> _saveBlockedKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_keywords', _blockedKeywords);
    setState(() {});
  }

  Future<void> _saveOverlaySettings(String position, int duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('overlay_position', position);
    await prefs.setInt('overlay_duration_seconds', duration);
    setState(() {
      _overlayPosition = position;
      _overlayDurationSeconds = duration;
    });
  }

  bool _isTimeInQuietHours(TimeOfDay start, TimeOfDay end, DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight quiet hours, e.g., 22:00 to 07:00
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  Future<void> _checkInstalledPresets() async {
    final defaultPresets = [
      {'pkg': 'com.whatsapp', 'name': 'WhatsApp', 'icon': Icons.chat, 'color': const Color(0xFF25D366)},
      {'pkg': 'com.facebook.orca', 'name': 'Messenger', 'icon': Icons.messenger, 'color': const Color(0xFF0084FF)},
      {'pkg': 'org.telegram.messenger', 'name': 'Telegram', 'icon': Icons.send, 'color': const Color(0xFF0088CC)},
      {'pkg': 'com.viber.voip', 'name': 'Viber', 'icon': Icons.phone_in_talk, 'color': const Color(0xFF7360F2)},
      {'pkg': 'com.zing.zalo', 'name': 'Zalo', 'icon': Icons.message, 'color': const Color(0xFF0068FF)},
      {'pkg': 'com.google.android.apps.messaging', 'name': 'SMS Messages', 'icon': Icons.sms, 'color': const Color(0xFF00B0FF)},
      {'pkg': 'com.google.android.gm', 'name': 'Gmail', 'icon': Icons.mail, 'color': const Color(0xFFEA4335)},
      {'pkg': 'com.facebook.katana', 'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)},
      {'pkg': 'com.instagram.android', 'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFE1306C)},
    ];

    final List<Map<String, dynamic>> verified = [];
    for (var preset in defaultPresets) {
      final pkg = preset['pkg'] as String;
      try {
        final isInstalled = await InstalledApps.isAppInstalled(pkg);
        if (isInstalled == true) {
          verified.add(preset);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _installedPresets = verified;
      });
    }
  }

  Future<void> _saveFilter(String packageName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_$packageName', value);
    setState(() {
      _appFilters[packageName] = value;
    });
  }

  void _handleNewNotification(NotificationItem item) async {
    // 1. Check Blocked Keywords (case-insensitive)
    final titleLower = item.title.toLowerCase();
    final textLower = item.text.toLowerCase();
    for (final kw in _blockedKeywords) {
      final kwLower = kw.toLowerCase();
      if (titleLower.contains(kwLower) || textLower.contains(kwLower)) {
        print("Notification blocked by keyword '$kw': ${item.title}");
        return;
      }
    }

    // 2. Check Quiet Hours
    if (_quietHoursEnabled) {
      if (_isTimeInQuietHours(_quietHoursStart, _quietHoursEnd, DateTime.now())) {
        print("Notification blocked by Quiet Hours schedule: ${item.title}");
        return;
      }
    }

    // Dynamically register new discovered apps
    if (!_appFilters.containsKey(item.packageName)) {
      _saveFilter(item.packageName, true);
    }

    // Check filter: default to true if not configured
    final isEnabled = _appFilters[item.packageName] ?? true;
    if (!isEnabled) {
      print("Notification from ${item.packageName} filtered out.");
      return;
    }

    // Add to history
    setState(() {
      _history.insert(0, item);
      if (_history.length > 50) _history.removeLast();
    });

    // Make sure we load the icon bytes to send to TV
    final pkg = item.packageName;
    Uint8List? iconBytes = _appIconCache[pkg];
    if (!_appIconCache.containsKey(pkg)) {
      try {
        final appInfo = await InstalledApps.getAppInfo(pkg);
        iconBytes = appInfo?.icon;
        _appIconCache[pkg] = iconBytes;
        if (mounted) setState(() {});
      } catch (_) {}
    }

    // Send to TV
    if (_isConnected) {
      String? base64Icon;
      if (iconBytes != null) {
        base64Icon = base64Encode(iconBytes);
      }
      _connector.sendNotification(
        item,
        base64Icon: base64Icon,
        overlayPosition: _overlayPosition,
        overlayDurationMs: _overlayDurationSeconds * 1000,
      );
    }
  }

  void _sendTestNotification() {
    final testItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: 'com.whatsapp',
      title: 'Jane Doe',
      text: 'Hello from your TV Mirror app! 📺✨',
      postTime: DateTime.now().millisecondsSinceEpoch,
    );
    _handleNewNotification(testItem);
  }

  @override
  Widget build(BuildContext context) {
    final views = [
      _buildConnectTab(),
      _buildFiltersTab(),
      _buildHistoryTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TV Notification Mirror',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkPermission();
              _connector.startScanning();
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0E17),
              Color(0xFF1B192A),
            ],
          ),
        ),
        child: Column(
          children: [
            if (!_hasPermission) _buildPermissionWarning(),
            Expanded(child: views[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF16161A),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Connect'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: 'Apps'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  // Permission warning banner
  Widget _buildPermissionWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
        border: Border.all(color: Theme.of(context).colorScheme.error, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notification access required to read and mirror phone notifications.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => _notifier.openSettings(),
            child: const Text('Enable', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Connect Tab
  Widget _buildConnectTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          if (!_isConnected) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showManualConnectDialog,
              icon: const Icon(Icons.link),
              label: const Text('Connect with IP Address'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available TVs in Network',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (_discoveredDevices.isEmpty)
              _buildEmptyDevicesCard()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final dev = _discoveredDevices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2E2A4A),
                        child: Icon(Icons.tv, color: Color(0xFF7F5AF0)),
                      ),
                      title: Text(dev.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${dev.ip}:${dev.port}'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showPairingDialog(dev),
                        child: const Text('Pair'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _isConnected ? Icons.check_circle_outline : Icons.cloud_off_outlined,
              size: 64,
              color: _isConnected ? Theme.of(context).colorScheme.secondary : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isConnected ? 'Connected to TV' : 'Not Connected',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_isConnected && _connector.connectedTvName != null) ...[
              const SizedBox(height: 8),
              Text(
                _connector.connectedTvName!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
            if (_isConnected) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _tvDndEnabled ? Icons.do_not_disturb_on : Icons.do_not_disturb_off,
                  color: _tvDndEnabled ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
                title: const Text('TV Do Not Disturb (DND)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Mute all notification popups on TV'),
                value: _tvDndEnabled,
                onChanged: (val) {
                  setState(() {
                    _tvDndEnabled = val;
                  });
                  _connector.sendDndToggle(val);
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setBool('tv_dnd_enabled', val);
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_isConnected) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _connector.disconnect(),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Disconnect'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => _connector.startScanning(),
                    icon: const Icon(Icons.search),
                    label: const Text('Scan Again'),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDevicesCard() {
    return Card(
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 20),
            Text(
              'Scanning for devices in local network...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPairingDialog(TVDevice device) async {
    final success = await _connector.startPairing(device);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to TV. Make sure the TV app is open.')),
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
        // StatefulBuilder lets us update loading state inside the dialog
        // without needing a full-screen overlay.
        bool isLoading = false;
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Pair with ${device.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading) ...[
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Connecting...', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                  ] else ...[
                    const Text('Enter the 4-digit PIN displayed on your TV screen:'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
              actions: isLoading
                  ? null // hide buttons while loading
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final pin = pinController.text.trim();
                          if (pin.length == 4) {
                            setDialogState(() => isLoading = true);
                            final isPaired = await _connector.confirmPairing(device, pin);
                            if (mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isPaired
                                      ? 'Successfully paired with ${device.name}!'
                                      : 'Incorrect PIN. Please try again.'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Connect'),
                      ),
                    ],
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Connect with IP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'TV IP Address',
                  hintText: 'e.g. 192.168.1.50 or 10.0.2.2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: 'e.g. 8080',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final ip = ipController.text.trim();
                final portStr = portController.text.trim();
                final port = int.tryParse(portStr) ?? 8080;
                
                if (ip.isNotEmpty) {
                  Navigator.pop(context); // close manual connection dialog
                  final device = TVDevice(name: 'Manual TV', ip: ip, port: port);
                  _showPairingDialog(device);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }


  void _showAddCustomAppDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Custom App Filter'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'App Package Name',
            hintText: 'e.g. com.spotify.music',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
    );
  }

  Widget _buildOverlaySettingsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tv, color: Color(0xFF7F5AF0)),
                SizedBox(width: 8),
                Text('TV Overlay Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Popup Position', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _overlayPosition,
                  dropdownColor: const Color(0xFF161624),
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      _saveOverlaySettings(val, _overlayDurationSeconds);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'top_right', child: Text('Top Right')),
                    DropdownMenuItem(value: 'top_left', child: Text('Top Left')),
                    DropdownMenuItem(value: 'bottom_right', child: Text('Bottom Right')),
                    DropdownMenuItem(value: 'bottom_left', child: Text('Bottom Left')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Display Duration', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('$_overlayDurationSeconds seconds', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            Slider(
              min: 2,
              max: 15,
              divisions: 13,
              label: '$_overlayDurationSeconds s',
              value: _overlayDurationSeconds.toDouble(),
              onChanged: (val) {
                _saveOverlaySettings(_overlayPosition, val.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    final startStr = _quietHoursStart.format(context);
    final endStr = _quietHoursEnd.format(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nights_stay, color: Color(0xFF2CB67D)),
                const SizedBox(width: 8),
                const Text('Quiet Hours (DND Schedule)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: _quietHoursEnabled,
                  onChanged: (val) {
                    _saveQuietHours(val, _quietHoursStart, _quietHoursEnd);
                  },
                ),
              ],
            ),
            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: _quietHoursStart,
                      );
                      if (selected != null) {
                        _saveQuietHours(_quietHoursEnabled, selected, _quietHoursEnd);
                      }
                    },
                    child: Text('Start: $startStr'),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  OutlinedButton(
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: _quietHoursEnd,
                      );
                      if (selected != null) {
                        _saveQuietHours(_quietHoursEnabled, _quietHoursStart, selected);
                      }
                    },
                    child: Text('End: $endStr'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordFilterCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_alt, color: Colors.orange),
                SizedBox(width: 8),
                Text('Blocked Keywords', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Notifications containing these keywords will not be sent to TV.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: 'e.g., spam, discount, OTP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (val) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty && !_blockedKeywords.contains(trimmed)) {
                        setState(() {
                          _blockedKeywords.add(trimmed);
                        });
                        _saveBlockedKeywords();
                        _keywordController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final val = _keywordController.text.trim();
                    if (val.isNotEmpty && !_blockedKeywords.contains(val)) {
                      setState(() {
                        _blockedKeywords.add(val);
                      });
                      _saveBlockedKeywords();
                      _keywordController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_blockedKeywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _blockedKeywords.map((kw) {
                  return Chip(
                    label: Text(kw),
                    onDeleted: () {
                      setState(() {
                        _blockedKeywords.remove(kw);
                      });
                      _saveBlockedKeywords();
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Filters Tab
  Widget _buildFiltersTab() {
    final defaultPresets = [
      {'pkg': 'com.whatsapp', 'name': 'WhatsApp', 'icon': Icons.chat, 'color': const Color(0xFF25D366)},
      {'pkg': 'com.facebook.orca', 'name': 'Messenger', 'icon': Icons.messenger, 'color': const Color(0xFF0084FF)},
      {'pkg': 'org.telegram.messenger', 'name': 'Telegram', 'icon': Icons.send, 'color': const Color(0xFF0088CC)},
      {'pkg': 'com.viber.voip', 'name': 'Viber', 'icon': Icons.phone_in_talk, 'color': const Color(0xFF7360F2)},
      {'pkg': 'com.zing.zalo', 'name': 'Zalo', 'icon': Icons.message, 'color': const Color(0xFF0068FF)},
      {'pkg': 'com.google.android.apps.messaging', 'name': 'SMS Messages', 'icon': Icons.sms, 'color': const Color(0xFF00B0FF)},
      {'pkg': 'com.google.android.gm', 'name': 'Gmail', 'icon': Icons.mail, 'color': const Color(0xFFEA4335)},
      {'pkg': 'com.facebook.katana', 'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)},
      {'pkg': 'com.instagram.android', 'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFE1306C)},
    ];

    // Find other package names configured or discovered in _appFilters
    final dynamicApps = _appFilters.keys
        .where((pkg) => !defaultPresets.any((preset) => preset['pkg'] == pkg))
        .map((pkg) => {
              'pkg': pkg,
              'name': NotificationItem.getAppName(pkg),
              'icon': _getAppIcon(pkg),
              'color': _getAppColor(pkg),
            })
        .toList();

    final allApps = [..._installedPresets, ...dynamicApps];

    final filteredApps = allApps.where((app) {
      final name = (app['name'] as String).toLowerCase();
      final pkg = (app['pkg'] as String).toLowerCase();
      final query = _filterSearchQuery.toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuietHoursCard(),
          _buildKeywordFilterCard(),
          _buildOverlaySettingsCard(),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'App Filters (${filteredApps.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                TextButton.icon(
                  onPressed: _showAddCustomAppDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Package'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _filterSearchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              final pkg = app['pkg'] as String;
              final name = app['name'] as String;
              final appIcon = app['icon'] as IconData;
              final appColor = app['color'] as Color;
              final isEnabled = _appFilters[pkg] ?? true;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: CircleAvatar(
                    backgroundColor: appColor.withValues(alpha: 0.2),
                    child: AppIconWidget(
                      packageName: pkg,
                      fallbackIcon: appIcon,
                      fallbackColor: appColor,
                      cache: _appIconCache,
                      size: 24,
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pkg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  value: isEnabled,
                  onChanged: (val) => _saveFilter(pkg, val),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _getAppIcon(String packageName) {
    switch (packageName) {
      case 'com.whatsapp': return Icons.chat;
      case 'com.facebook.orca': return Icons.messenger;
      case 'org.telegram.messenger': return Icons.send;
      case 'com.viber.voip': return Icons.phone_in_talk;
      case 'com.zing.zalo': return Icons.message;
      case 'com.google.android.apps.messaging': return Icons.sms;
      case 'com.google.android.gm': return Icons.mail;
      case 'com.facebook.katana': return Icons.facebook;
      case 'com.instagram.android': return Icons.camera_alt;
      default: return Icons.notifications;
    }
  }

  Color _getAppColor(String packageName) {
    switch (packageName) {
      case 'com.whatsapp': return const Color(0xFF25D366);
      case 'com.facebook.orca': return const Color(0xFF0084FF);
      case 'org.telegram.messenger': return const Color(0xFF0088CC);
      case 'com.viber.voip': return const Color(0xFF7360F2);
      case 'com.zing.zalo': return const Color(0xFF0068FF);
      case 'com.google.android.apps.messaging': return const Color(0xFF00B0FF);
      case 'com.google.android.gm': return const Color(0xFFEA4335);
      case 'com.facebook.katana': return const Color(0xFF1877F2);
      case 'com.instagram.android': return const Color(0xFFE1306C);
      default: return const Color(0xFF7F5AF0);
    }
  }

  // History Tab
  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'No notifications captured yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final appName = NotificationItem.getAppName(item.packageName);
        final appIcon = _getAppIcon(item.packageName);
        final appColor = _getAppColor(item.packageName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: appColor.withValues(alpha: 0.2),
                  radius: 20,
                  child: AppIconWidget(
                    packageName: item.packageName,
                    fallbackIcon: appIcon,
                    fallbackColor: appColor,
                    cache: _appIconCache,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            appName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            DateTime.fromMillisecondsSinceEpoch(item.postTime)
                                .toLocal()
                                .toString()
                                .substring(11, 16),
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(item.text, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppIconWidget extends StatefulWidget {
  final String packageName;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;
  final Map<String, Uint8List?> cache;

  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 24.0,
    required this.cache,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIconIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _loadIconIfNeeded();
    }
  }

  void _loadIconIfNeeded() async {
    final pkg = widget.packageName;
    if (widget.cache.containsKey(pkg)) {
      return; // Already queried
    }

    if (_loading) return;

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final appInfo = await InstalledApps.getAppInfo(pkg);
      if (mounted) {
        setState(() {
          widget.cache[pkg] = appInfo?.icon;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          widget.cache[pkg] = null; // cache failure
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedIcon = widget.cache[widget.packageName];
    if (cachedIcon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          cachedIcon,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Icon(
      widget.fallbackIcon,
      color: widget.fallbackColor,
      size: widget.size,
    );
  }
}
