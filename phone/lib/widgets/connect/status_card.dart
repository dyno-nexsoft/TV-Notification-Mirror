import 'package:shared/shared.dart';
import '../../services/connector_service.dart';
import '../../services/filter_service.dart';

/// The connection status section shown at the top of the Connect tab.
/// Displays current connection state, TV name, DND toggle, and action buttons using Yaru UI.
class StatusCard extends StatelessWidget {
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
  final bool isConnected;
  final String? connectedTvName;
  final bool tvDndEnabled;
  final AppSettings settings;
  final ConnectorService connector;
  final VoidCallback onScanAgain;
  final VoidCallback onSendTest;
  final ValueChanged<bool> onDndChanged;

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: Text(
        isConnected ? 'Connected to TV' : 'Not Connected',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: Column(
        children: [
          YaruListTile(
            leading: Icon(
              isConnected ? YaruIcons.ok_simple : YaruIcons.cloud,
            ),
            title: Text(
              isConnected
                  ? (connectedTvName ?? 'Connected')
                  : 'No Active TV Connection',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isConnected
                  ? 'Notifications are being mirrored in real-time.'
                  : 'Scan local Wi-Fi network to discover TV.',
            ),
          ),
          if (isConnected) ...[
            const Divider(),
            YaruListTile(
              leading: Icon(
                tvDndEnabled ? YaruIcons.error : YaruIcons.ok,
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
                OutlinedButton.icon(
                  onPressed: () => connector.disconnect(),
                  icon: const Icon(YaruIcons.power),
                  label: const Text('Disconnect'),
                ),
                ElevatedButton.icon(
                  onPressed: onSendTest,
                  icon: const Icon(YaruIcons.go_next),
                  label: const Text('Send Test'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(YaruIcons.search),
                  label: const Text('Scan Again'),
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
