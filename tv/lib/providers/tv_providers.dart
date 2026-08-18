import 'dart:async';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/shared.dart';

import '../services/overlay_service.dart';

part 'tv_providers.g.dart';

// ── App Toast Provider ────────────────────────────────────────────────────

class ToastData {
  const ToastData(this.message, this.timestamp);
  final String message;
  final DateTime timestamp;
}

@Riverpod(keepAlive: true)
class AppToast extends _$AppToast {
  @override
  ToastData? build() => null;

  void show(String message) {
    state = ToastData(message, DateTime.now());
  }
}

// ── Permissions Provider ───────────────────────────────────────────────────

class TvPermissionsState {
  const TvPermissionsState({
    this.hasOverlayPermission = false,
    this.hasNotificationPermission = false,
  });

  final bool hasOverlayPermission;
  final bool hasNotificationPermission;

  bool get isFullyGranted => hasOverlayPermission && hasNotificationPermission;
}

@Riverpod(keepAlive: true)
class TvPermissions extends _$TvPermissions {
  @override
  FutureOr<TvPermissionsState> build() async {
    return _check();
  }

  Future<TvPermissionsState> _check() async {
    final overlayStatus = await OverlayService.checkPermission();
    final notificationStatus =
        await OverlayService.checkNotificationPermission();

    final newState = TvPermissionsState(
      hasOverlayPermission: overlayStatus,
      hasNotificationPermission: notificationStatus,
    );

    if (overlayStatus && notificationStatus) {
      final isRunning = await FlutterBackgroundService().isRunning();
      if (!isRunning) {
        await FlutterBackgroundService().startService();
      }
    }

    return newState;
  }

  Future<void> checkPermissions() async {
    state = await AsyncValue.guard(() async {
      return _check();
    });
  }
}

// ── IP Address Provider ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<String> tvIp(Ref ref) async {
  try {
    InternetAddress? best;
    var bestRank = 3;
    for (final interface in await NetworkInterface.list()) {
      final rank = _interfaceRank(interface.name);
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.isLoopback &&
            _isUsableAddress(addr.address) &&
            rank < bestRank) {
          best = addr;
          bestRank = rank;
        }
      }
    }
    return best?.address ?? 'Disconnected';
  } catch (e) {
    return 'Error fetching IP';
  }
}

/// True for an IPv4 address a phone could actually reach over the LAN: skips
/// link-local (169.254.x.x) and the unspecified address.
bool _isUsableAddress(String address) {
  if (address == '0.0.0.0') return false;
  return InternetAddress.tryParse(address)?.isLinkLocal != true;
}

/// Prefers the real Wi-Fi/Ethernet adapter over virtual ones (VPN tunnels,
/// USB tethering, aliases) that Fire TV and other set-top boxes expose.
int _interfaceRank(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('wlan') || lower.contains('wifi')) return 0;
  if (lower.contains('eth') || lower.contains('rmnet')) return 1;
  return 2;
}

// ── TV Background Service State Provider ───────────────────────────────────

class TvServiceData {
  const TvServiceData({
    this.pairingPin,
    this.qrToken,
    this.serverPort,
    this.isRunning = false,
    this.isDnd = false,
    this.dndUntilEpochMs,
    this.pairedClients = const [],
    this.activeTokens = const {},
    this.notificationHistory = const [],
  });

  final String? pairingPin;
  final String? qrToken;
  final int? serverPort;
  final bool isRunning;
  final bool isDnd;
  final int? dndUntilEpochMs;
  final List<MirrorDevice> pairedClients;
  final Set<String> activeTokens;
  final List<NotificationItem> notificationHistory;

  TvServiceData copyWith({
    String? pairingPin,
    String? qrToken,
    int? serverPort,
    bool? isRunning,
    bool? isDnd,
    int? dndUntilEpochMs,
    List<MirrorDevice>? pairedClients,
    Set<String>? activeTokens,
    List<NotificationItem>? notificationHistory,
  }) {
    return TvServiceData(
      pairingPin: pairingPin ?? this.pairingPin,
      qrToken: qrToken ?? this.qrToken,
      serverPort: serverPort ?? this.serverPort,
      isRunning: isRunning ?? this.isRunning,
      isDnd: isDnd ?? this.isDnd,
      dndUntilEpochMs: dndUntilEpochMs ?? this.dndUntilEpochMs,
      pairedClients: pairedClients ?? this.pairedClients,
      activeTokens: activeTokens ?? this.activeTokens,
      notificationHistory: notificationHistory ?? this.notificationHistory,
    );
  }
}

@Riverpod(keepAlive: true)
class TvServiceState extends _$TvServiceState {
  StreamSubscription? _stateSub;

  @override
  TvServiceData build() {
    _stateSub?.cancel();

    final service = FlutterBackgroundService();

    _stateSub = service.on('stateUpdate').listen((data) {
      if (data != null) {
        final clientsList =
            (data['clients'] as List?)
                ?.map(
                  (e) => MirrorDevice.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList() ??
            [];
        final historyList =
            (data['history'] as List?)
                ?.map(
                  (e) => NotificationItem.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList() ??
            [];
        state = TvServiceData(
          pairingPin: data['pin'],
          qrToken: data['qrToken'],
          serverPort: data['port'] as int?,
          isRunning: data['isRunning'] ?? false,
          isDnd: data['isDnd'] ?? false,
          dndUntilEpochMs: data['dndUntilEpochMs'],
          pairedClients: clientsList,
          activeTokens: Set<String>.from(data['activeTokens'] ?? []),
          notificationHistory: historyList,
        );
      }
    });

    ref.onDispose(() {
      _stateSub?.cancel();
    });

    return const TvServiceData();
  }

  void toggleDnd() {
    FlutterBackgroundService().invoke('toggleDnd');
  }

  void setDndForDuration(Duration duration) {
    FlutterBackgroundService().invoke('setDndForDuration', {
      'minutes': duration.inMinutes,
    });
  }

  void removeClient(String token) {
    FlutterBackgroundService().invoke('removeClient', {'token': token});
  }

  void renameClient(String token, String newName) {
    FlutterBackgroundService().invoke('renameClient', {
      'token': token,
      'newName': newName,
    });
  }

  void clearHistory() {
    FlutterBackgroundService().invoke('clearHistory');
  }

  void regenerateQrCode() {
    FlutterBackgroundService().invoke('regenerateQrToken');
    ref.read(appToastProvider.notifier).show('New QR code generated');
  }

  void testOverlay() {
    OverlayService.showOverlay(
      title: 'Test Notification',
      text: 'Connection is working perfectly! 🎉',
      appName: 'TV System',
    );
  }
}
