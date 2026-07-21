import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _saveFilter(String packageName, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('filter_$packageName', value);
    setState(() {
      _appFilters[packageName] = value;
    });
  }

  void _handleNewNotification(NotificationItem item) {
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

    // Send to TV
    if (_isConnected) {
      _connector.sendNotification(item);
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
        color: Theme.of(context).colorScheme.error.withOpacity(0.15),
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


  // Filters Tab
  Widget _buildFiltersTab() {
    final apps = [
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
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
              child: Icon(appIcon, color: appColor),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(pkg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            value: isEnabled,
            onChanged: (val) => _saveFilter(pkg, val),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
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
                  child: Icon(appIcon, color: appColor, size: 20),
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
