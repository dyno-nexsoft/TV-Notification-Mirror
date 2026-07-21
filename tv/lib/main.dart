import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/background_service.dart';
import 'services/overlay_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app immediately so UI renders without waiting for service init.
  // initializeBackgroundService() is fast (just configure, not start),
  // but we still fire it unawaited to avoid blocking the first frame.
  initializeBackgroundService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Notification Receiver',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0B10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7F5AF0),
          secondary: Color(0xFF2CB67D),
          surface: Color(0xFF16151D),
          error: Color(0xFFFF5252),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF16151D),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        fontFamily: 'Outfit',
      ),
      home: const TvMainScreen(),
    );
  }
}

class TvMainScreen extends StatefulWidget {
  const TvMainScreen({super.key});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen> with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _hasNotificationPermission = false;
  String _tvIp = 'Loading IP...';
  
  // Background state
  String? _pairingPin;
  bool _isRunning = false;
  bool _isDnd = false;
  List<dynamic> _pairedClients = [];
  Set<String> _activeTokens = {};
  List<dynamic> _notificationHistory = [];

  StreamSubscription? _stateSub;
  StreamSubscription? _overlaySub;
  StreamSubscription? _hideOverlaySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Run permission check and IP fetch in parallel instead of sequentially.
    Future.wait([_checkPermission(), _fetchIp()]);

    // Listen to background service updates
    _stateSub = FlutterBackgroundService().on('stateUpdate').listen((data) {
      if (data != null && mounted) {
        setState(() {
          _pairingPin = data['pin'];
          _isRunning = data['isRunning'];
          _isDnd = data['isDnd'];
          _pairedClients = data['clients'] ?? [];
          _activeTokens = Set<String>.from(data['activeTokens'] ?? []);
          _notificationHistory = data['history'] ?? [];
        });
      }
    });

    // Listen to overlay show/hide commands forwarded from the background service
    _overlaySub = FlutterBackgroundService().on('showOverlay').listen((data) {
      if (data != null) {
        OverlayService.showOverlay(
          title: data['title'] ?? '',
          text: data['text'] ?? '',
          appName: data['appName'] ?? '',
          base64Icon: data['base64Icon'],
          overlayPosition: data['overlayPosition'],
          overlayDurationMs: data['overlayDuration'],
        );
      }
    });

    _hideOverlaySub = FlutterBackgroundService().on('hideOverlay').listen((_) {
      OverlayService.hideOverlay();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _overlaySub?.cancel();
    _hideOverlaySub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final overlayStatus = await OverlayService.checkPermission();
    final notificationStatus = await OverlayService.checkNotificationPermission();
    setState(() {
      _hasOverlayPermission = overlayStatus;
      _hasNotificationPermission = notificationStatus;
    });

    if (overlayStatus && notificationStatus) {
      final isRunning = await FlutterBackgroundService().isRunning();
      if (!isRunning) {
        await FlutterBackgroundService().startService();
      }
    }
  }

  Future<void> _fetchIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _tvIp = addr.address;
            });
            return;
          }
        }
      }
      setState(() {
        _tvIp = 'Disconnected';
      });
    } catch (e) {
      setState(() {
        _tvIp = 'Error fetching IP';
      });
    }
  }

  void _toggleDnd() {
    FlutterBackgroundService().invoke('toggleDnd');
  }

  void _removeClient(String token) {
    FlutterBackgroundService().invoke('removeClient', {'token': token});
  }

  void _confirmRemoveClient(String token, String deviceName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Remove "$deviceName" from paired devices?'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _removeClient(token);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _testOverlay() {
    OverlayService.showOverlay(
      title: 'Duyệt thử nghiệm',
      text: 'Kết nối đang hoạt động hoàn hảo! 🎉',
      appName: 'Hệ thống TV',
    );
  }

  Future<bool> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Exit TV Mirror?'),
        content: const Text(
          'Do you want to exit the app?\n'
          'The WebSocket server will continue running in the background to mirror notifications.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmDialog();
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
      body: Row(
        children: [
          // Left Navigation / Actions panel
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(40),
              color: const Color(0xFF0F0E16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TV MIRROR',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF7F5AF0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gương thông báo điện thoại lên TV',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Spacer(),
                  
                  if (!_hasOverlayPermission) ...[
                    _buildOverlayWarningCard(),
                  ] else if (!_hasNotificationPermission) ...[
                    _buildNotificationWarningCard(),
                  ] else ...[
                    _buildServerInfoCard(),
                  ],
                  
                  const Spacer(),
                  
                  // Action buttons
                  TvButton(
                    onPressed: (_hasOverlayPermission && _hasNotificationPermission) 
                        ? _toggleDnd 
                        : _checkPermission,
                    color: _isDnd ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                    label: (!_hasOverlayPermission || !_hasNotificationPermission) 
                        ? 'Check Permission Again'
                        : (_isDnd ? 'Turn DND OFF' : 'Turn DND ON'),
                    icon: _isDnd ? Icons.do_not_disturb_on : Icons.do_not_disturb_off,
                  ),
                  const SizedBox(height: 16),
                  if (_hasOverlayPermission && _hasNotificationPermission) ...[
                    TvButton(
                      onPressed: _testOverlay,
                      color: const Color(0xFF2E2A4A),
                      label: 'Test Overlay Notification',
                      icon: Icons.play_arrow,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Right details panel
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pairing Box
                  if (_pairingPin != null)
                    _buildPairingBox()
                  else if (_activeTokens.isNotEmpty)
                    _buildConnectedBox()
                  else
                    _buildWaitingBox(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Paired Devices
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Paired Devices',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _pairedClients.isEmpty
                                    ? _buildEmptyClients()
                                    : ListView.builder(
                                        itemCount: _pairedClients.length,
                                        itemBuilder: (context, index) {
                                          final client = _pairedClients[index];
                                          final token = client['token'] as String? ?? '';
                                          return PairedDeviceCard(
                                            deviceName: client['deviceName'] ?? 'Unknown Phone',
                                            ip: client['ip'] ?? '',
                                            isOnline: _activeTokens.contains(token),
                                            onRemove: () => _confirmRemoveClient(
                                              token,
                                              client['deviceName'] ?? 'Unknown Phone',
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        // Vertical divider line
                        Container(
                          width: 1,
                          color: Colors.white10,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        const SizedBox(width: 30),
                        // Right column: Recent Notifications history
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recent Notifications',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _notificationHistory.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Chưa có thông báo nào.',
                                          style: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _notificationHistory.length,
                                        itemBuilder: (context, index) {
                                          final item = _notificationHistory[index];
                                          final title = item['title'] ?? '';
                                          final text = item['text'] ?? '';
                                          final appIconBase64 = item['appIcon'] as String?;
                                          
                                          // Format timestamp to Time string, e.g. 15:30
                                          final timestamp = item['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
                                          final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
                                          final timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                                          return Card(
                                            color: const Color(0xFF161624),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: const Color(0xFF7F5AF0).withValues(alpha: 0.1),
                                                child: appIconBase64 != null
                                                    ? ClipOval(
                                                        child: Image.memory(
                                                          base64Decode(appIconBase64),
                                                          width: 24,
                                                          height: 24,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : const Icon(Icons.notifications, color: Color(0xFF7F5AF0), size: 20),
                                              ),
                                              title: Text(
                                                title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                text,
                                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: Text(
                                                timeStr,
                                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildOverlayWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                const Text('Permission Needed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This application requires Overlay Permission to display notifications over other apps.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TvButton(
              onPressed: () => OverlayService.requestPermission(),
              color: Theme.of(context).colorScheme.error,
              label: 'Grant Overlay Permission',
              icon: Icons.open_in_new,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                const Text('Permission Needed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This application requires Notification Permission to run background connectivity.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TvButton(
              onPressed: () => OverlayService.requestNotificationPermission(),
              color: Theme.of(context).colorScheme.error,
              label: 'Grant Notification Permission',
              icon: Icons.notifications_active,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi, color: Color(0xFF2CB67D)),
                const SizedBox(width: 12),
                Text(
                  _isRunning ? 'Server Active' : 'Server Idle',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('IP Address: $_tvIp', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Port: 8080', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              'Status: ${_isDnd ? "Do Not Disturb (Muted)" : "Listening for phone..."}',
              style: TextStyle(
                fontSize: 14,
                color: _isDnd ? Colors.redAccent : const Color(0xFF2CB67D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPairingBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A4A).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7F5AF0), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined, size: 48, color: Color(0xFF7F5AF0)),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Pairing Request', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  'Enter this PIN on your phone:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF7F5AF0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _pairingPin!,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBox() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for Phone Connection',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Open the TV Notification Mirror app on your phone to pair.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedBox() {
    // Find the device name(s) of active token(s)
    String connectedDevicesText = 'Active connection established.';
    if (_pairedClients.isNotEmpty && _activeTokens.isNotEmpty) {
      final activeNames = _pairedClients
          .where((c) => _activeTokens.contains(c['token']))
          .map((c) => c['deviceName'] ?? 'Unknown Phone')
          .toList();
      if (activeNames.isNotEmpty) {
        connectedDevicesText = 'Connected to: ${activeNames.join(", ")}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16151D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2CB67D).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0x1F2CB67D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 36, color: Color(0xFF2CB67D)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Connected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  connectedDevicesText,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClients() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('No devices paired yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

// Custom TvButton widget that highlights on Remote D-pad focus
class TvButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final String label;
  final IconData icon;

  const TvButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  State<TvButton> createState() => _TvButtonState();
}

class _TvButtonState extends State<TvButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focus) {
        setState(() {
          _isFocused = focus;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: _isFocused ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2)]
              : [],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: _isFocused ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            ),
            elevation: _isFocused ? 12 : 4,
          ),
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 24),
          label: Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

/// A TV-optimised paired device card.
/// The info area and the delete button are SEPARATE focus nodes so that
/// D-pad navigation can land on each independently.
class PairedDeviceCard extends StatefulWidget {
  final String deviceName;
  final String ip;
  final bool isOnline;
  final VoidCallback onRemove;

  const PairedDeviceCard({
    super.key,
    required this.deviceName,
    required this.ip,
    required this.isOnline,
    required this.onRemove,
  });

  @override
  State<PairedDeviceCard> createState() => _PairedDeviceCardState();
}

class _PairedDeviceCardState extends State<PairedDeviceCard> {
  bool _cardFocused = false;
  bool _deleteFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: const Color(0xFF16151D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _cardFocused
                ? const Color(0xFF7F5AF0)
                : Colors.white10,
            width: _cardFocused ? 2 : 1,
          ),
          boxShadow: _cardFocused
              ? [const BoxShadow(color: Color(0x557F5AF0), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          children: [
            // ── Device info (focusable, pressing OK does nothing / future detail) ──
            Expanded(
              child: Focus(
                onFocusChange: (f) => setState(() => _cardFocused = f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2A4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_android, color: Color(0xFF7F5AF0), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.deviceName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              // Online / offline status dot
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isOnline
                                      ? const Color(0xFF2CB67D)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isOnline ? widget.ip : 'Offline',
                            style: TextStyle(
                              color: widget.isOnline ? Colors.grey : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Delete button — its own focus node, fully independent ──
            Focus(
              onFocusChange: (f) => setState(() => _deleteFocused = f),
              // GestureDetector only handles touch. TV remotes send KEY events
              // (D-pad centre = LogicalKeyboardKey.select). We must catch them
              // here with onKeyEvent, otherwise pressing OK does nothing.
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.select ||
                     event.logicalKey == LogicalKeyboardKey.enter ||
                     event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                  widget.onRemove();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                onTap: widget.onRemove, // still works for mouse/touch
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _deleteFocused
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: _deleteFocused
                        ? Border.all(color: Colors.white, width: 2)
                        : Border.all(color: Colors.white12),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: _deleteFocused ? Colors.white : Colors.redAccent,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
