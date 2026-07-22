import 'package:shared/shared.dart';
import '../services/overlay_service.dart';
import 'tv_button.dart';

/// Shown while a phone is mid-pairing, surfacing the PIN it must confirm.
class PairingBox extends StatelessWidget {
  final String pin;

  const PairingBox({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return YaruSection(
      headline: const Text('New Pairing Request'),
      child: YaruListTile(
        leading: Icon(YaruIcons.key, size: 36, color: primaryColor),
        title: const Text(
          'Enter this PIN on your phone:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            pin,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.white,
            ),
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
        title: Text(
          'Waiting for Phone Connection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Open the TV Notification Mirror app on your phone to pair.',
        ),
      ),
    );
  }
}

/// Shown once at least one paired phone has an active WebSocket connection.
class ConnectedBox extends StatelessWidget {
  final List<dynamic> pairedClients;
  final Set<String> activeTokens;

  const ConnectedBox({
    super.key,
    required this.pairedClients,
    required this.activeTokens,
  });

  @override
  Widget build(BuildContext context) {
    String connectedDevicesText = 'Active connection established.';
    if (pairedClients.isNotEmpty && activeTokens.isNotEmpty) {
      final activeNames = pairedClients
          .where((c) => activeTokens.contains(c['token']))
          .map((c) => (c['deviceName'] ?? c['name'] ?? 'Unknown Phone').toString())
          .toList();
      if (activeNames.isNotEmpty) {
        connectedDevicesText = 'Connected to: ${activeNames.join(", ")}';
      }
    }

    return YaruSection(
      headline: const Text('Connection Status'),
      child: YaruListTile(
        leading: const Icon(YaruIcons.ok_simple, size: 36, color: Colors.greenAccent),
        title: const Text(
          'Phone Connected',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(connectedDevicesText),
      ),
    );
  }
}

/// Summarizes the mirror server's running/DND state and the TV's local IP,
/// shown once both required permissions have been granted.
class ServerInfoCard extends StatelessWidget {
  final bool isRunning;
  final bool isDnd;
  final String tvIp;

  const ServerInfoCard({
    super.key,
    required this.isRunning,
    required this.isDnd,
    required this.tvIp,
  });

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: Row(
        children: [
          Icon(YaruIcons.network_wireless, color: isRunning ? Colors.greenAccent : Colors.grey),
          const SizedBox(width: 8),
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
              style: TextStyle(
                fontSize: 14,
                color: isDnd ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
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
    final errorColor = Theme.of(context).colorScheme.error;
    return YaruSection(
      headline: Row(
        children: [
          Icon(YaruIcons.warning, color: errorColor),
          const SizedBox(width: 8),
          const Text('Permission Needed'),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This application requires Overlay Permission to display notifications over other apps.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TvButton(
              onPressed: () => OverlayService.requestPermission(),
              color: errorColor,
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
    final errorColor = Theme.of(context).colorScheme.error;
    return YaruSection(
      headline: Row(
        children: [
          Icon(YaruIcons.warning, color: errorColor),
          const SizedBox(width: 8),
          const Text('Permission Needed'),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This application requires Notification Permission to run background connectivity.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TvButton(
              onPressed: () => OverlayService.requestNotificationPermission(),
              color: errorColor,
              label: 'Grant Notification Permission',
              icon: YaruIcons.notification,
            ),
          ],
        ),
      ),
    );
  }
}
