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
      initialNotificationTitle: MirrorProtocol.appName,
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

  Future<void> reloadSettings() async {
    appFilters = await FilterService.loadFilters();
  }

  await reloadSettings();

  // Listen to reload requests from UI
  if (service is AndroidServiceInstance) {
    service.on('reloadSettings').listen((event) async {
      await reloadSettings();
      debugPrint("Background isolate: Settings reloaded");
    });
  }

  // Forward connection errors to UI
  connector.errorStream.listen((message) {
    service.invoke('connectionError', {'message': message});
  });

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

  service.on('checkConnection').listen((_) {
    connector.checkConnection();
  });

  service.on('sendTestNotification').listen((event) async {
    if (event == null) return;
    final item = NotificationItem.fromJson(Map<String, dynamic>.from(event));
    String? base64Icon;
    try {
      final appInfo = await InstalledApps.getAppInfo(item.packageName);
      if (appInfo != null && appInfo.icon != null) {
        base64Icon = base64Encode(appInfo.icon!);
      }
    } catch (e) {
      debugPrint("Failed to load icon for test notification: $e");
    }
    connector.sendNotification(item, base64Icon: base64Icon);
  });

  // Notification Listening & Filtering — phone only filters by app allowlist.
  // TV decides category-based filtering (call/text/images) and display settings.
  notificationService.notificationStream.listen((item) async {
    final isAppAllowed = MirrorFilterEvaluator.isAppEnabled(
      item.packageName,
      appFilters,
    );

    if (isAppAllowed) {
      String? base64Icon;
      try {
        final appInfo = await InstalledApps.getAppInfo(item.packageName);
        if (appInfo != null && appInfo.icon != null) {
          base64Icon = base64Encode(appInfo.icon!);
        }
      } catch (e) {
        debugPrint("Failed to load icon for ${item.packageName}: $e");
      }

      connector.sendNotification(item, base64Icon: base64Icon);
      service.invoke('notificationSent', item.toJson());
    }
  });

  notificationService.notificationRemovedStream.listen((id) {
    connector.sendNotificationRemoved(id, '');
  });
}
