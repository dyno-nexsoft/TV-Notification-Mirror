import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared/shared.dart';

import 'connector_service.dart';
import 'filter_service.dart';
import 'notification_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      notificationChannelId: 'phone_mirror_service_channel',
      initialNotificationTitle: 'TV Notification Mirror',
      initialNotificationContent: 'Running in background...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final connector = ConnectorService();
  final notificationService = NotificationService();

  var appFilters = <String, bool>{};
  var appSettings = const AppSettings(
    blockedKeywords: [],
    overlayDurationSeconds: 5,
    overlayPosition: 'bottom',
    quietHoursEnabled: false,
    quietHoursStart: TimeOfDay(hour: 22, minute: 0),
    quietHoursEnd: TimeOfDay(hour: 7, minute: 0),
    tvDndEnabled: false,
  );

  Future<void> reloadSettings() async {
    appFilters = await FilterService.loadFilters();
    appSettings = await FilterService.loadSettings();
  }

  await reloadSettings();

  // Listen to reload requests from UI
  if (service is AndroidServiceInstance) {
    service.on('reloadSettings').listen((event) async {
      await reloadSettings();
      debugPrint("Background isolate: Settings reloaded");
    });
  }

  // Periodic state sync to UI
  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (service is AndroidServiceInstance) {
      service.invoke('stateUpdate', {
        'isConnected': connector.isConnected,
        'connectedTvName': connector.connectedTvName,
        'discoveredDevices':
            connector.discoveredDevices.map((d) => d.toJson()).toList(),
      });
    }
  });

  // UI commands
  service.on('startScanning').listen((_) {
    connector.startScanning();
  });

  service.on('stopScanning').listen((_) {
    connector.stopScanning();
  });

  service.on('startPairing').listen((event) async {
    if (event == null) return;
    final device = MirrorDevice.fromJson(Map<String, dynamic>.from(event));
    final success = await connector.startPairing(device);
    service.invoke('pairingResult', {'success': success});
  });

  service.on('confirmPairing').listen((event) async {
    if (event == null) return;
    final device =
        MirrorDevice.fromJson(Map<String, dynamic>.from(event['device']));
    final pin = event['pin'] as String;
    final success = await connector.confirmPairing(device, pin);
    service.invoke('pairingConfirmResult', {'success': success});
  });

  service.on('pairViaQr').listen((event) async {
    if (event == null) return;
    final rawQrData = event['rawQrData'] as String;
    final success = await connector.pairViaQr(rawQrData);
    service.invoke('pairViaQrResult', {'success': success});
  });

  service.on('disconnect').listen((_) {
    connector.disconnect();
  });

  service.on('sendDndToggle').listen((event) {
    if (event != null && event['enabled'] != null) {
      connector.sendDndToggle(event['enabled'] as bool);
    }
  });

  service.on('sendTestNotification').listen((event) {
    if (event == null) return;
    final item = NotificationItem.fromJson(Map<String, dynamic>.from(event));
    connector.sendNotification(
      item,
      overlayPosition: appSettings.overlayPosition,
      overlayDurationMs: appSettings.overlayDurationSeconds * 1000,
    );
  });

  // Notification Listening & Filtering
  notificationService.notificationStream.listen((item) async {
    if (!appSettings.masterMirrorEnabled) {
      debugPrint("Mirroring disabled by master switch, ignoring notification.");
      return;
    }

    final isBlockedByKw = MirrorFilterEvaluator.findMatchingBlockedKeyword(
          item.title,
          item.text,
          appSettings.blockedKeywords,
        ) !=
        null;

    final isBlockedByQuiet = appSettings.quietHoursEnabled &&
        MirrorFilterEvaluator.isTimeInQuietHours(
          appSettings.quietHoursStart,
          appSettings.quietHoursEnd,
          DateTime.now(),
        );

    final isAppAllowed = MirrorFilterEvaluator.isAppEnabled(
      item.packageName,
      appFilters,
    );

    if (!isBlockedByKw && !isBlockedByQuiet && isAppAllowed) {
      // Need icon? Yes. Wait, FilterService.loadFilters() doesn't load icons!
      // In phone app, iconCache is loaded from InstalledApps package.
      // We can fetch it on the fly for the specific package to save memory in background!
      String? base64Icon;
      try {
        final appInfo = await InstalledApps.getAppInfo(item.packageName);
        if (appInfo != null && appInfo.icon != null) {
          base64Icon = base64Encode(appInfo.icon!);
        }
      } catch (e) {
        debugPrint("Failed to load icon for ${item.packageName}: $e");
      }

      connector.sendNotification(
        item,
        base64Icon: base64Icon,
        overlayPosition: appSettings.overlayPosition,
        overlayDurationMs: appSettings.overlayDurationSeconds * 1000,
      );

      service.invoke('notificationSent', item.toJson());
    }
  });

  notificationService.notificationRemovedStream.listen((id) {
    connector.sendNotificationRemoved(id, '');
  });
}
