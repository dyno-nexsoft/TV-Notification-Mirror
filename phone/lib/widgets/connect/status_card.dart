import 'package:shared/shared.dart';
import '../../services/connector_service.dart';
import '../../services/filter_service.dart';

/// The connection status section shown at the top of the Connect tab.
/// Displays current connection state, TV name, DND toggle, and action buttons using Yaru UI.
class StatusCard extends StatelessWidget {
  final bool isConnected;
  final String? connectedTvName;
  final bool tvDndEnabled;
  final AppSettings settings;
  final ConnectorService connector;
  final VoidCallback onScanAgain;
  final VoidCallback onSendTest;
  final ValueChanged<bool> onDndChanged;

  const StatusCard({
    super.key,
    required this.isConnected,
    required this.connectedTvName,
    required this.tvDndEnabled,
    required this.settings,
    required this.connector,
    required this.onScanAgain,
    required this.onSendTest,
    required this.onDndChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return YaruSection(
      headline: Text(
        isConnected ? 'Connected to TV' : 'Not Connected',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: Column(
        children: [
          YaruListTile(
            leading: Icon(
              isConnected ? YaruIcons.ok_simple : YaruIcons.cloud,
              size: 40,
              color: isConnected ? Colors.greenAccent : Colors.grey,
            ),
            title: Text(
              isConnected ? (connectedTvName ?? 'Connected') : 'No Active TV Connection',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isConnected
                  ? 'Notifications are being mirrored in real-time.'
                  : 'Scan local Wi-Fi network to discover TV.',
            ),
          ),
          if (isConnected) ...[
            const Divider(color: Colors.white10),
            YaruListTile(
              leading: Icon(
                tvDndEnabled ? YaruIcons.error : YaruIcons.ok,
                color: tvDndEnabled ? colorScheme.error : colorScheme.primary,
              ),
              title: const Text(
                'TV Do Not Disturb (DND)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Mute all notification popups on TV'),
              trailing: YaruSwitch(
                value: tvDndEnabled,
                onChanged: onDndChanged,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isConnected) ...[
                YaruOptionButton(
                  onPressed: () => connector.disconnect(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(YaruIcons.power, color: Colors.redAccent, size: 18),
                      SizedBox(width: 6),
                      Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
                YaruOptionButton(
                  onPressed: onSendTest,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(YaruIcons.go_next, size: 18),
                      SizedBox(width: 6),
                      Text('Send Test'),
                    ],
                  ),
                ),
              ] else ...[
                YaruOptionButton(
                  onPressed: onScanAgain,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(YaruIcons.search, size: 18),
                      SizedBox(width: 6),
                      Text('Scan Again'),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
