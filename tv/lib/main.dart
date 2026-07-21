import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/background_service.dart';
import 'services/overlay_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await initializeBackgroundService();
  
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

  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _fetchIp();
    
    // Listen to background service updates
    _stateSub = FlutterBackgroundService().on('stateUpdate').listen((data) {
      if (data != null && mounted) {
        setState(() {
          _pairingPin = data['pin'];
          _isRunning = data['isRunning'];
          _isDnd = data['isDnd'];
          _pairedClients = data['clients'] ?? [];
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
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

  void _testOverlay() {
    OverlayService.showOverlay(
      title: 'Duyệt thử nghiệm',
      text: 'Kết nối đang hoạt động hoàn hảo! 🎉',
      appName: 'Hệ thống TV',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  if (_pairingPin != null) ...[
                    _buildPairingBox()
                  ] else ...[
                    _buildWaitingBox()
                  ],
                  const SizedBox(height: 40),
                  
                  // Paired Clients list
                  const Text(
                    'Paired Devices',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _pairedClients.isEmpty
                        ? _buildEmptyClients()
                        : ListView.builder(
                            itemCount: _pairedClients.length,
                            itemBuilder: (context, index) {
                              final client = _pairedClients[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const Icon(Icons.phone_android, color: Color(0xFF7F5AF0)),
                                  title: Text(
                                    client['deviceName'] ?? 'Unknown Phone',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(client['ip'] ?? ''),
                                  trailing: TvListTileButton(
                                    icon: Icons.delete_outline,
                                    color: Colors.redAccent,
                                    onPressed: () => _removeClient(client['token']),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
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
      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
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
        color: const Color(0xFF2E2A4A).withOpacity(0.3),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
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
              ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)]
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

class TvListTileButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const TvListTileButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<TvListTileButton> createState() => _TvListTileButtonState();
}

class _TvListTileButtonState extends State<TvListTileButton> {
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isFocused ? widget.color.withOpacity(0.2) : Colors.transparent,
          border: _isFocused ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
