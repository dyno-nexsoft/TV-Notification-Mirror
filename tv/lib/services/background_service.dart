import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'server_service.dart';

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
      initialNotificationContent: 'WebSocket Server is running ngầm...',
      foregroundServiceNotificationId: 999,
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

  // Listen for overlay messages from ServerService and forward them to the UI isolate
  server.overlayStream.listen((event) {
    if (service is AndroidServiceInstance) {
      if (event['action'] == 'show') {
        service.invoke('showOverlay', {
          'title': event['title'],
          'text': event['text'],
          'appName': event['appName'],
          'base64Icon': event['base64Icon'],
          'overlayPosition': event['overlayPosition'],
          'overlayDuration': event['overlayDuration'],
        });
      } else if (event['action'] == 'hide') {
        service.invoke('hideOverlay');
      }
    }
  });

  // Periodically send state updates to the UI
  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (service is AndroidServiceInstance) {
      service.invoke('stateUpdate', {
        'pin': server.currentPin,
        'isRunning': server.isRunning,
        'isDnd': server.isDndEnabled,
        'clients': server.pairedClients
            .map((c) => {
                  'deviceName': c.name,
                  'ip': c.ip,
                  'token': c.token,
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
    server.isDndEnabled = !server.isDndEnabled;
    debugPrint("DND mode toggled to: ${server.isDndEnabled}");
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

  service.on('stopService').listen((event) async {
    await server.stopServer();
    service.stopSelf();
  });
}
