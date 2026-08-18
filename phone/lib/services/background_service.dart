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

  void logDebug(String source, String message,
      [DebugLogLevel level = DebugLogLevel.info]) {
    service.invoke(
      'debugLog',
      DebugLogEntry(
        time: DateTime.now(),
        level: level,
        source: source,
        message: message,
      ).toMap(),
    );
  }

  logDebug('service', 'Background isolate started');

  var appFilters = <String, bool>{};

  Future<void> reloadSettings() async {
    appFilters = await FilterService.loadFilters();
  }

  await reloadSettings();

  // Forward connection errors to UI
  connector.errorStream.listen((message) {
    service.invoke('connectionError', {'message': message});
  });

  // Forward connector lifecycle logs to the UI's debug log buffer.
  connector.logStream.listen((message) {
    logDebug('connector', message);
  });

  // Listen to reload requests from UI
  if (service is AndroidServiceInstance) {
    service.on('reloadSettings').listen((event) async {
      await reloadSettings();
      logDebug('service', 'Settings reloaded');
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
    final outcome = await connector.pairViaQr(rawQrData);
    service.invoke('pairViaQrResult', {
      'success': outcome.success,
      'message': outcome.message,
    });
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
      logDebug('notification', 'Received from ${item.appName}: ${item.title}');
      String? base64Icon;
      try {
        final appInfo = await InstalledApps.getAppInfo(item.packageName);
        if (appInfo != null && appInfo.icon != null) {
          base64Icon = base64Encode(appInfo.icon!);
        }
      } catch (e) {
        logDebug(
          'notification',
          "Failed to load icon for ${item.packageName}: $e",
          DebugLogLevel.warn,
        );
      }

      connector.sendNotification(item, base64Icon: base64Icon);
      service.invoke('notificationSent', item.toJson());
    } else {
      logDebug(
        'filter',
        "Blocked notification from ${item.appName} (${item.packageName})",
        DebugLogLevel.debug,
      );
    }
  });

  notificationService.notificationRemovedStream.listen((id) {
    logDebug('notification', 'Notification removed: $id');
    connector.sendNotificationRemoved(id, '');
  });
}
