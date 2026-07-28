import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'server_service.dart';
import 'tv_settings_service.dart';

/// Registers the `flutter_background_service` configuration so the mirror
/// server can keep running as a foreground service after the UI is backgrounded.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'tv_mirror_service_channel',
      initialNotificationTitle: 'TV Notification Mirror',
      initialNotificationContent: 'WebSocket Server is running in background...',
      foregroundServiceNotificationId: 999,
      foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

/// Entry point run in the background isolate: starts [ServerService] and
/// wires its events (overlay requests, state changes) to the UI isolate,
/// and the UI's commands (DND toggle, remove client, stop) back to it.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final server = ServerService();
  await server.init();
  await server.startServer('Android TV Server', 8080);

  var tvSettings = await TvSettingsService.load();
  server.updateSettings(tvSettings);

  Future<void> reloadTvSettings() async {
    tvSettings = await TvSettingsService.load();
    server.updateSettings(tvSettings);
  }

  if (service is AndroidServiceInstance) {
    service.on('reloadSettings').listen((event) async {
      await reloadTvSettings();
      debugPrint("TV background isolate: settings reloaded");
    });
  }

  // Listen for overlay messages from ServerService and forward them to the UI isolate.
  // The TV always overrides the incoming anchor/duration with its own local
  // settings, since it — not the phone — owns what its own screen looks like.
  server.overlayStream.listen((event) {
    if (service is AndroidServiceInstance) {
      if (event['action'] == 'show') {
        service.invoke('showOverlay', {
          'title': event['title'],
          'text': event['text'],
          'appName': event['appName'],
          'base64Icon': event['base64Icon'],
          'overlayPosition': tvSettings.anchorPosition,
          'overlayDuration': tvSettings.overlayDurationSeconds * 1000,
          'overlayOpacity': tvSettings.overlayOpacity,
          'alertSoundUri': tvSettings.alertSoundUri,
          'category': event['category'],
        });
      } else if (event['action'] == 'hide') {
        service.invoke('hideOverlay');
      }
    }
  });

  // Periodically send state updates to the UI
  Timer.periodic(const Duration(seconds: 1), (timer) {
    server.checkDndExpiry();
    if (service is AndroidServiceInstance) {
      service.invoke('stateUpdate', {
        'pin': server.currentPin,
        'qrToken': server.currentQrToken,
        'isRunning': server.isRunning,
        'isDnd': server.isDndEnabled,
        'clients': server.pairedClients
            .map((c) => {
                  'deviceName': c.name,
                  'ip': c.ip,
                  'token': c.token,
                  'lastSyncedAt': c.lastSyncedAt,
                })
            .toList(),
        // Which tokens currently have an active WebSocket connection.
        'activeTokens': server.activeTokens.toList(),
        'history': server.notificationHistory,
      });
    }
  });

  // Listen for actions from the UI
  service.on('toggleDnd').listen((event) {
    server.toggleDndIndefinite();
    debugPrint("DND mode toggled to: ${server.isDndEnabled}");
  });

  service.on('setDndForDuration').listen((event) {
    final minutes = event?['minutes'] as int?;
    if (minutes != null) {
      server.setDndForDuration(Duration(minutes: minutes));
    }
  });

  service.on('removeClient').listen((event) {
    if (event != null && event['token'] != null) {
      final token = event['token'] as String;
      final clientToRemove =
          server.pairedClients.firstWhere((c) => c.token == token);
      server.removeClient(clientToRemove);
      debugPrint("Removed client: ${clientToRemove.name}");
    }
  });

  service.on('renameClient').listen((event) async {
    if (event != null && event['token'] != null && event['newName'] != null) {
      await server.renameClient(
          event['token'] as String, event['newName'] as String);
      debugPrint("Renamed client ${event['token']} to ${event['newName']}");
    }
  });

  service.on('clearHistory').listen((event) {
    server.clearHistory();
  });

  service.on('regenerateQrToken').listen((event) {
    server.regenerateQrToken();
  });

  service.on('stopService').listen((event) async {
    await server.stopServer();
    service.stopSelf();
  });
}
