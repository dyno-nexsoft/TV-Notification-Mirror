import 'package:shared/shared.dart';
import '../services/overlay_service.dart';
import 'tv_button.dart';

/// Shown while a phone is mid-pairing, surfacing the PIN it must confirm.
class PairingBox extends StatelessWidget {
  const PairingBox({super.key, required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return YaruSection(
      headline: const Text('New Pairing Request'),
      child: YaruListTile(
        leading: const Icon(YaruIcons.key),
        title: const Text('Enter this PIN on your phone:'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            pin,
          ),
        ),
      ),
    );
  }
}

/// Default state before any phone has paired or connected.
class WaitingBox extends StatelessWidget {
  const WaitingBox({super.key});

  @override
  Widget build(BuildContext context) {
    return const YaruSection(
      headline: Text('Waiting for Connection'),
      child: YaruListTile(
        leading: YaruCircularProgressIndicator(),
        title: Text('Waiting for Phone Connection'),
        subtitle: Text(
          'Open the TV Notification Mirror app on your phone to pair.',
        ),
      ),
    );
  }
}

/// Shown once at least one paired phone has an active WebSocket connection.
class ConnectedBox extends StatelessWidget {
  const ConnectedBox({
    super.key,
    required this.pairedClients,
    required this.activeTokens,
  });
  final List<MirrorDevice> pairedClients;
  final Set<String> activeTokens;

  @override
  Widget build(BuildContext context) {
    var connectedDevicesText = 'Active connection established.';
    if (pairedClients.isNotEmpty && activeTokens.isNotEmpty) {
      final activeNames = pairedClients
          .where((c) => c.token != null && activeTokens.contains(c.token))
          .map((c) => c.name)
          .toList();
      if (activeNames.isNotEmpty) {
        connectedDevicesText = 'Connected to: ${activeNames.join(", ")}';
      }
    }

    return YaruSection(
      headline: const Text('Connection Status'),
      child: YaruListTile(
        leading: const Icon(YaruIcons.ok_simple),
        title: const Text('Phone Connected'),
        subtitle: Text(connectedDevicesText),
      ),
    );
  }
}

/// Summarizes the mirror server's running/DND state and the TV's local IP,
/// shown once both required permissions have been granted.
class ServerInfoCard extends StatelessWidget {
  const ServerInfoCard({
    super.key,
    required this.isRunning,
    required this.isDnd,
    required this.tvIp,
  });
  final bool isRunning;
  final bool isDnd;
  final String tvIp;

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: Row(
        spacing: 8,
        children: [
          const Icon(YaruIcons.network_wireless),
          Text(isRunning ? 'Server Active' : 'Server Idle'),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YaruListTile(
            title: Text('IP Address: $tvIp'),
            subtitle: const Text('Port: 8080'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Status: ${isDnd ? "Do Not Disturb (Muted)" : "Listening for phone..."}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocks the dashboard until `SYSTEM_ALERT_WINDOW` overlay permission is
/// granted — required before any notification can be drawn over other apps.
class OverlayWarningCard extends StatelessWidget {
  const OverlayWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: const Row(
        spacing: 8,
        children: [
          Icon(YaruIcons.warning),
          Text('Permission Needed'),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Text(
              'This application requires Overlay Permission to display notifications over other apps.',
            ),
            TvButton(
              onPressed: () => OverlayService.requestPermission(),
              label: 'Grant Overlay Permission',
              icon: YaruIcons.external_link,
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocks the dashboard until `POST_NOTIFICATIONS` permission is granted —
/// required on API 33+ before the background mirror service can start.
class NotificationWarningCard extends StatelessWidget {
  const NotificationWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: const Row(
        spacing: 8,
        children: [
          Icon(YaruIcons.warning),
          Text('Permission Needed'),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Text(
              'This application requires Notification Permission to run background connectivity.',
            ),
            TvButton(
              onPressed: () => OverlayService.requestNotificationPermission(),
              label: 'Grant Notification Permission',
              icon: YaruIcons.notification,
            ),
          ],
        ),
      ),
    );
  }
}
