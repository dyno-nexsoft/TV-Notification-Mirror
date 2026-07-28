import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/shared.dart';

import '../services/connector_service.dart';
import '../services/filter_service.dart';

part 'phone_providers.g.dart';

// ── App Toast Provider ────────────────────────────────────────────────────────

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

// ── Permission Provider ─────────────────────────────────────────────────────

/// Manages Android notification listener permission state.
@Riverpod(keepAlive: true)
class Permission extends _$Permission {
  static const _methodsChannel =
      MethodChannel('com.dyno.tv_notification_mirror/methods');

  @override
  FutureOr<bool> build() async {
    return _checkPermission();
  }

  Future<void> checkPermission() async {
    state = await AsyncValue.guard(_checkPermission);
  }

  Future<bool> _checkPermission() async {
    try {
      return await _methodsChannel.invokeMethod('checkPermission');
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _methodsChannel.invokeMethod('openSettings');
    } catch (_) {}
  }
}

// ── Connector State & Notifier ──────────────────────────────────────────────

class PhoneConnectorState {
  const PhoneConnectorState({
    this.discoveredDevices = const [],
    this.isConnected = false,
    this.connectedTvName,
  });

  final List<TVDevice> discoveredDevices;
  final bool isConnected;
  final String? connectedTvName;

  PhoneConnectorState copyWith({
    List<TVDevice>? discoveredDevices,
    bool? isConnected,
    String? connectedTvName,
  }) {
    return PhoneConnectorState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isConnected: isConnected ?? this.isConnected,
      connectedTvName: connectedTvName ?? this.connectedTvName,
    );
  }
}

@Riverpod(keepAlive: true)
class Connector extends _$Connector {
  StreamSubscription? _stateSub;

  @override
  PhoneConnectorState build() {
    final service = FlutterBackgroundService();

    _stateSub?.cancel();
    _stateSub = service.on('stateUpdate').listen((event) {
      if (event == null) return;

      final isConnected = event['isConnected'] as bool? ?? false;
      final connectedTvName = event['connectedTvName'] as String?;

      final rawDevices = event['discoveredDevices'] as List<dynamic>? ?? [];
      final discoveredDevices = rawDevices
          .map((d) => MirrorDevice.fromJson(Map<String, dynamic>.from(d)))
          .toList();

      state = state.copyWith(
        isConnected: isConnected,
        connectedTvName: connectedTvName,
        discoveredDevices: discoveredDevices,
      );
    });

    ref.onDispose(() {
      _stateSub?.cancel();
    });

    return const PhoneConnectorState();
  }

  void startScanning() {
    FlutterBackgroundService().invoke('startScanning');
  }

  void stopScanning() {
    FlutterBackgroundService().invoke('stopScanning');
  }

  Future<bool> startPairing(TVDevice device) async {
    final service = FlutterBackgroundService();
    final completer = Completer<bool>();

    StreamSubscription? sub;
    sub = service.on('pairingResult').listen((event) {
      if (event != null) {
        completer.complete(event['success'] as bool? ?? false);
      }
      sub?.cancel();
    });

    service.invoke('startPairing', device.toJson());

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      sub?.cancel();
      return false;
    });
  }

  Future<bool> confirmPairing(TVDevice device, String pin) async {
    final service = FlutterBackgroundService();
    final completer = Completer<bool>();

    StreamSubscription? sub;
    sub = service.on('pairingConfirmResult').listen((event) {
      if (event != null) {
        completer.complete(event['success'] as bool? ?? false);
      }
      sub?.cancel();
    });

    service.invoke('confirmPairing', {
      'device': device.toJson(),
      'pin': pin,
    });

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      sub?.cancel();
      return false;
    });
  }

  Future<bool> pairViaQr(String rawQrData) async {
    final service = FlutterBackgroundService();
    final completer = Completer<bool>();

    StreamSubscription? sub;
    sub = service.on('pairViaQrResult').listen((event) {
      if (event != null) {
        completer.complete(event['success'] as bool? ?? false);
      }
      sub?.cancel();
    });

    service.invoke('pairViaQr', {'rawQrData': rawQrData});

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      sub?.cancel();
      return false;
    });
  }

  void disconnect() {
    FlutterBackgroundService().invoke('disconnect');
  }

  void sendDndToggle(bool val) {
    FlutterBackgroundService().invoke('sendDndToggle', {'enabled': val});
  }

  void sendNotification(NotificationItem item) {
    FlutterBackgroundService().invoke('sendTestNotification', item.toJson());
  }
}

// ── App Settings Provider ───────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  FutureOr<AppSettings> build() async {
    return FilterService.loadSettings();
  }

  Future<void> updateSettings(AppSettings updated) async {
    final previousState = state;
    state = AsyncData(updated);

    try {
      await FilterService.saveOverlaySettings(
        position: updated.overlayPosition,
        durationSeconds: updated.overlayDurationSeconds,
      );
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setTvDnd(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(tvDndEnabled: enabled));

    try {
      ref.read(connectorProvider.notifier).sendDndToggle(enabled);
      await FilterService.saveTvDnd(enabled);
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setMasterMirrorEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(masterMirrorEnabled: enabled));

    try {
      await FilterService.saveMasterMirrorEnabled(enabled);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setCallNotificationsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(callNotificationsEnabled: enabled));

    try {
      await FilterService.saveCallNotificationsEnabled(enabled);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setTextNotificationsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(textNotificationsEnabled: enabled));

    try {
      await FilterService.saveTextNotificationsEnabled(enabled);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setImagePreviewsEnabled(bool enabled) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(imagePreviewsEnabled: enabled));

    try {
      await FilterService.saveImagePreviewsEnabled(enabled);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> setAlertSoundUri(String uri) async {
    final current = state.value;
    if (current == null) return;

    final previousState = state;
    state = AsyncData(current.copyWith(alertSoundUri: uri));

    try {
      await FilterService.saveAlertSoundUri(uri);
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }
}

// ── Filters & Installed Apps State & Notifier ──────────────────────────────

class PhoneFiltersState {
  const PhoneFiltersState({
    this.appFilters = const {},
    this.iconCache = const {},
    this.installedPresets = const [],
  });

  final Map<String, bool> appFilters;
  final Map<String, Uint8List?> iconCache;
  final List<AppPreset> installedPresets;

  PhoneFiltersState copyWith({
    Map<String, bool>? appFilters,
    Map<String, Uint8List?>? iconCache,
    List<AppPreset>? installedPresets,
  }) {
    return PhoneFiltersState(
      appFilters: appFilters ?? this.appFilters,
      iconCache: iconCache ?? this.iconCache,
      installedPresets: installedPresets ?? this.installedPresets,
    );
  }
}

@Riverpod(keepAlive: true)
class Filters extends _$Filters {
  @override
  FutureOr<PhoneFiltersState> build() async {
    final filters = await FilterService.loadFilters();
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      withIcon: true,
    );

    final iconCache = <String, Uint8List?>{};
    final loadedApps = <AppPreset>[];
    for (final app in apps) {
      final pkg = app.packageName;
      if (app.icon != null) iconCache[pkg] = app.icon;
      loadedApps.add(AppPreset(pkg: pkg, name: app.name));
    }

    loadedApps.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return PhoneFiltersState(
      appFilters: filters,
      iconCache: iconCache,
      installedPresets: loadedApps,
    );
  }

  Future<void> saveFilter(String packageName, bool value) async {
    final currentState = state.value;
    if (currentState == null) return;

    final previousState = state;
    state = AsyncData(currentState.copyWith(
      appFilters: {...currentState.appFilters, packageName: value},
    ));

    try {
      await FilterService.saveFilter(packageName, value);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }

  Future<void> addCustomAppPreset(String packageName, String name) async {
    final currentState = state.value;
    if (currentState == null) return;

    var updatedPresets = currentState.installedPresets;
    if (!updatedPresets.any((a) => a.pkg == packageName)) {
      updatedPresets = [
        ...currentState.installedPresets,
        AppPreset(pkg: packageName, name: name),
      ];
      updatedPresets
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    final previousState = state;
    state = AsyncData(currentState.copyWith(
      installedPresets: updatedPresets,
      appFilters: {...currentState.appFilters, packageName: true},
    ));

    try {
      await FilterService.saveFilter(packageName, true);
      FlutterBackgroundService().invoke('reloadSettings');
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }
}

// ── Notification History Provider ──────────────────────────────────────────

@Riverpod(keepAlive: true)
class History extends _$History {
  StreamSubscription? _notifSub;

  @override
  List<NotificationItem> build() {
    final service = FlutterBackgroundService();

    _notifSub?.cancel();
    _notifSub = service.on('notificationSent').listen((event) {
      if (event == null) return;
      final item = NotificationItem.fromJson(Map<String, dynamic>.from(event));
      addNotification(item);
    });

    ref.onDispose(() {
      _notifSub?.cancel();
    });

    return [];
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }

  void clearHistory() {
    state = [];
  }
}
