import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/shared.dart';

import '../services/connector_service.dart';
import '../services/filter_service.dart';
import '../services/notification_service.dart';

part 'phone_providers.g.dart';

// ── Singletons / Service Access ─────────────────────────────────────────────

@Riverpod(keepAlive: true)
ConnectorService connectorService(Ref ref) {
  final service = ConnectorService();
  ref.onDispose(() {
    service.stopScanning();
    service.disconnect();
  });
  return service;
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService();
}

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
  @override
  FutureOr<bool> build() async {
    return ref.read(notificationServiceProvider).checkPermission();
  }

  Future<void> checkPermission() async {
    state = await AsyncValue.guard(() async {
      return ref.read(notificationServiceProvider).checkPermission();
    });
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
  StreamSubscription<List<TVDevice>>? _deviceSub;
  StreamSubscription<bool>? _connectionSub;

  @override
  PhoneConnectorState build() {
    final connector = ref.watch(connectorServiceProvider);

    _deviceSub?.cancel();
    _connectionSub?.cancel();

    _deviceSub = connector.devicesStream.listen((devices) {
      state = state.copyWith(discoveredDevices: devices);
    });

    _connectionSub = connector.connectionStateStream.listen((isConnected) {
      state = state.copyWith(
        isConnected: isConnected,
        connectedTvName: connector.connectedTvName,
      );
    });

    ref.onDispose(() {
      _deviceSub?.cancel();
      _connectionSub?.cancel();
    });

    connector.startScanning();

    return PhoneConnectorState(
      isConnected: connector.isConnected,
      connectedTvName: connector.connectedTvName,
    );
  }

  void startScanning() {
    ref.read(connectorServiceProvider).startScanning();
  }

  void stopScanning() {
    ref.read(connectorServiceProvider).stopScanning();
  }

  Future<bool> startPairing(TVDevice device) {
    return ref.read(connectorServiceProvider).startPairing(device);
  }

  Future<bool> confirmPairing(TVDevice device, String pin) async {
    final success =
        await ref.read(connectorServiceProvider).confirmPairing(device, pin);
    if (success) {
      state = state.copyWith(
        isConnected: true,
        connectedTvName: ref.read(connectorServiceProvider).connectedTvName,
      );
    }
    return success;
  }

  void disconnect() {
    ref.read(connectorServiceProvider).disconnect();
    state = state.copyWith(isConnected: false);
  }

  void sendDndToggle(bool val) {
    ref.read(connectorServiceProvider).sendDndToggle(val);
  }

  void sendNotification(
    NotificationItem item, {
    String? base64Icon,
    String? overlayPosition,
    int? overlayDurationMs,
  }) {
    ref.read(connectorServiceProvider).sendNotification(
          item,
          base64Icon: base64Icon,
          overlayPosition: overlayPosition,
          overlayDurationMs: overlayDurationMs,
        );
  }

  void sendNotificationRemoved(String id, String packageName) {
    ref.read(connectorServiceProvider).sendNotificationRemoved(id, packageName);
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
      await FilterService.saveQuietHours(
        enabled: updated.quietHoursEnabled,
        start: updated.quietHoursStart,
        end: updated.quietHoursEnd,
      );
      await FilterService.saveBlockedKeywords(updated.blockedKeywords);
      await FilterService.saveOverlaySettings(
        position: updated.overlayPosition,
        durationSeconds: updated.overlayDurationSeconds,
      );
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
    } catch (e) {
      state = previousState;
      ref.read(appToastProvider.notifier).show('Error: $e');
    }
  }
}

// ── Notification History Provider ──────────────────────────────────────────

@Riverpod(keepAlive: true)
class History extends _$History {
  StreamSubscription<NotificationItem>? _notifSub;
  StreamSubscription<String>? _removedSub;

  @override
  List<NotificationItem> build() {
    final notifierService = ref.watch(notificationServiceProvider);
    final connector = ref.read(connectorProvider.notifier);

    _notifSub?.cancel();
    _removedSub?.cancel();

    _notifSub = notifierService.notificationStream.listen((item) {
      final filtersState = ref.read(filtersProvider).value;
      final settings = ref.read(settingsProvider).value;

      if (filtersState == null || settings == null) return;

      final filters = filtersState.appFilters;

      final isBlockedByKw = MirrorFilterEvaluator.findMatchingBlockedKeyword(
            item.title,
            item.text,
            settings.blockedKeywords,
          ) !=
          null;

      final isBlockedByQuiet = settings.quietHoursEnabled &&
          MirrorFilterEvaluator.isTimeInQuietHours(
            settings.quietHoursStart,
            settings.quietHoursEnd,
            DateTime.now(),
          );

      final isAppAllowed = MirrorFilterEvaluator.isAppEnabled(
        item.packageName,
        filters,
      );

      if (!isBlockedByKw && !isBlockedByQuiet && isAppAllowed) {
        addNotification(item);
        final iconBytes = filtersState.iconCache[item.packageName];
        final base64Icon = iconBytes != null ? base64Encode(iconBytes) : null;
        connector.sendNotification(
          item,
          base64Icon: base64Icon,
          overlayPosition: settings.overlayPosition,
          overlayDurationMs: settings.overlayDurationSeconds * 1000,
        );
      }
    });

    _removedSub = notifierService.notificationRemovedStream.listen((id) {
      connector.sendNotificationRemoved(id, '');
    });

    ref.onDispose(() {
      _notifSub?.cancel();
      _removedSub?.cancel();
    });

    return [];
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }
}
