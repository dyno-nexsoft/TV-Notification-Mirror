import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared/shared.dart';

import '../services/overlay_service.dart';
import '../widgets/paired_device_card.dart';
import '../widgets/status_info_boxes.dart';
import '../widgets/tv_button.dart';

/// TV main dashboard screen — listens to background service state updates
/// and provides D-pad friendly UI for pairing, managing clients, and DND settings.
class TvMainScreen extends StatefulWidget {
  const TvMainScreen({super.key});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen> with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _hasNotificationPermission = false;
  String _tvIp = 'Loading IP...';

  // Background service state
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
    Future.wait([_checkPermission(), _fetchIp()]);

    _stateSub = FlutterBackgroundService().on('stateUpdate').listen((data) {
      if (data != null && mounted) {
        setState(() {
          _pairingPin = data['pin'];
          _isRunning = data['isRunning'] ?? false;
          _isDnd = data['isDnd'] ?? false;
          _pairedClients = data['clients'] ?? [];
          _activeTokens = Set<String>.from(data['activeTokens'] ?? []);
          _notificationHistory = data['history'] ?? [];
        });
      }
    });

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
    final notificationStatus =
        await OverlayService.checkNotificationPermission();
    if (mounted) {
      setState(() {
        _hasOverlayPermission = overlayStatus;
        _hasNotificationPermission = notificationStatus;
      });
    }

    if (overlayStatus && notificationStatus) {
      final isRunning = await FlutterBackgroundService().isRunning();
      if (!isRunning) {
        await FlutterBackgroundService().startService();
      }
    }
  }

  Future<void> _fetchIp() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (mounted) setState(() => _tvIp = addr.address);
            return;
          }
        }
      }
      if (mounted) setState(() => _tvIp = 'Disconnected');
    } catch (e) {
      if (mounted) setState(() => _tvIp = 'Error fetching IP');
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).colorScheme.error;

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
            // Left Panel
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TV MIRROR',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gương thông báo điện thoại lên TV',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Spacer(),
                    if (!_hasOverlayPermission) ...[
                      const OverlayWarningCard(),
                    ] else if (!_hasNotificationPermission) ...[
                      const NotificationWarningCard(),
                    ] else ...[
                      ServerInfoCard(
                        isRunning: _isRunning,
                        isDnd: _isDnd,
                        tvIp: _tvIp,
                      ),
                    ],
                    const Spacer(),
                    TvButton(
                      onPressed: (_hasOverlayPermission &&
                              _hasNotificationPermission)
                          ? _toggleDnd
                          : _checkPermission,
                      color: _isDnd ? errorColor : primaryColor,
                      label: (!_hasOverlayPermission ||
                              !_hasNotificationPermission)
                          ? 'Check Permission Again'
                          : (_isDnd ? 'Turn DND OFF' : 'Turn DND ON'),
                      icon: _isDnd
                          ? Icons.do_not_disturb_on
                          : Icons.do_not_disturb_off,
                    ),
                    const SizedBox(height: 16),
                    if (_hasOverlayPermission &&
                        _hasNotificationPermission) ...[
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

            // Right Panel
            Expanded(
              flex: 2,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_pairingPin != null)
                      PairingBox(pin: _pairingPin!)
                    else if (_activeTokens.isNotEmpty)
                      ConnectedBox(
                        pairedClients: _pairedClients,
                        activeTokens: _activeTokens,
                      )
                    else
                      const WaitingBox(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left sub-column: Paired Devices
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Paired Devices',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _pairedClients.isEmpty
                                      ? const _EmptyClientsCard()
                                      : ListView.builder(
                                          itemCount: _pairedClients.length,
                                          itemBuilder: (context, index) {
                                            final client =
                                                _pairedClients[index];
                                            final token =
                                                client['token'] as String? ?? '';
                                            final deviceName =
                                                client['deviceName'] ??
                                                    'Unknown Phone';
                                            return PairedDeviceCard(
                                              deviceName: deviceName,
                                              ip: client['ip'] ?? '',
                                              isOnline:
                                                  _activeTokens.contains(token),
                                              onRemove: () =>
                                                  _confirmRemoveClient(
                                                      token, deviceName),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            width: 1,
                            color: Colors.white10,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          const SizedBox(width: 20),
                          // Right sub-column: Notifications history
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Notifications',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _notificationHistory.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Chưa có thông báo nào.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount:
                                              _notificationHistory.length,
                                          itemBuilder: (context, index) {
                                            final item =
                                                _notificationHistory[index];
                                            final title = item['title'] ?? '';
                                            final text = item['text'] ?? '';
                                            final appIconBase64 =
                                                item['appIcon'] as String?;
                                            final timestamp =
                                                item['timestamp'] as int? ??
                                                    DateTime.now()
                                                        .millisecondsSinceEpoch;
                                            final dt = DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    timestamp);
                                            final timeStr =
                                                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: YaruListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: primaryColor
                                                      .withValues(alpha: 0.15),
                                                  child: appIconBase64 != null
                                                      ? ClipOval(
                                                          child: Image.memory(
                                                            base64Decode(
                                                                appIconBase64),
                                                            width: 24,
                                                            height: 24,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                      : Icon(
                                                          YaruIcons.notification,
                                                          color: primaryColor,
                                                          size: 20,
                                                        ),
                                                ),
                                                title: Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  text,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                trailing: Text(
                                                  timeStr,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
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
}

class _EmptyClientsCard extends StatelessWidget {
  const _EmptyClientsCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No devices paired yet.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
