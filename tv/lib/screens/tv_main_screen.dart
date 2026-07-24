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

part 'tv_main_screen_dialogs.dart';
part 'tv_main_screen_panels.dart';
part 'tv_main_screen_notifications.dart';

/// TV main dashboard screen — listens to background service state updates
/// and provides D-pad friendly UI for pairing, managing clients, and DND settings.
class TvMainScreen extends StatefulWidget {
  const TvMainScreen({super.key});

  @override
  State<TvMainScreen> createState() => _TvMainScreenState();
}

class _TvMainScreenState extends State<TvMainScreen>
    with WidgetsBindingObserver {
  bool _hasOverlayPermission = false;
  bool _hasNotificationPermission = false;
  String _tvIp = 'Loading IP...';

  // Background service state
  String? _pairingPin;
  bool _isRunning = false;
  bool _isDnd = false;
  List<MirrorDevice> _pairedClients = [];
  Set<String> _activeTokens = {};
  List<NotificationItem> _notificationHistory = [];

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
        final clientsList = (data['clients'] as List?)
                ?.map((e) =>
                    MirrorDevice.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        final historyList = (data['history'] as List?)
                ?.map((e) =>
                    NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        setState(() {
          _pairingPin = data['pin'];
          _isRunning = data['isRunning'] ?? false;
          _isDnd = data['isDnd'] ?? false;
          _pairedClients = clientsList;
          _activeTokens = Set<String>.from(data['activeTokens'] ?? []);
          _notificationHistory = historyList;
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
      builder: (dialogCtx) => _RemoveDeviceDialog(
        deviceName: deviceName,
        onConfirm: () {
          Navigator.pop(dialogCtx);
          _removeClient(token);
        },
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
      builder: (dialogCtx) => const _ExitConfirmDialog(),
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
              child: _LeftControlPanel(
                hasOverlayPermission: _hasOverlayPermission,
                hasNotificationPermission: _hasNotificationPermission,
                isRunning: _isRunning,
                isDnd: _isDnd,
                tvIp: _tvIp,
                primaryColor: primaryColor,
                errorColor: errorColor,
                onToggleDnd: _toggleDnd,
                onCheckPermission: _checkPermission,
                onTestOverlay: _testOverlay,
              ),
            ),

            // Right Panel
            Expanded(
              flex: 2,
              child: _RightInfoPanel(
                pairingPin: _pairingPin,
                pairedClients: _pairedClients,
                activeTokens: _activeTokens,
                notificationHistory: _notificationHistory,
                primaryColor: primaryColor,
                onRemoveClient: _confirmRemoveClient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
