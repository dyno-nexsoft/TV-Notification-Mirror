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
    for (final interface in await NetworkInterface.list()) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return 'Disconnected';
  } catch (e) {
    return 'Error fetching IP';
  }
}

// ── TV Background Service State Provider ───────────────────────────────────

class TvServiceData {
  const TvServiceData({
    this.pairingPin,
    this.qrToken,
    this.isRunning = false,
    this.isDnd = false,
    this.dndUntilEpochMs,
    this.pairedClients = const [],
    this.activeTokens = const {},
    this.notificationHistory = const [],
  });

  final String? pairingPin;
  final String? qrToken;
  final bool isRunning;
  final bool isDnd;
  final int? dndUntilEpochMs;
  final List<MirrorDevice> pairedClients;
  final Set<String> activeTokens;
  final List<NotificationItem> notificationHistory;

  TvServiceData copyWith({
    String? pairingPin,
    String? qrToken,
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
