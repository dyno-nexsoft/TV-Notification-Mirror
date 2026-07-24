import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';

/// The connection status section shown at the top of the Connect tab.
/// Displays current connection state, TV name, DND toggle, and action buttons using Yaru UI.
class StatusCard extends ConsumerWidget {
  const StatusCard({
    super.key,
    required this.onSendTest,
  });

  final VoidCallback onSendTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectorState = ref.watch(connectorProvider);
    final asyncSettings = ref.watch(settingsProvider);
    final isConnected = connectorState.isConnected;
    final connectedTvName = connectorState.connectedTvName;
    final tvDndEnabled = asyncSettings.value?.tvDndEnabled ?? false;

    return YaruSection(
      headline: Text(
        isConnected ? 'Connected to TV' : 'Not Connected',
      ),
      child: Column(
        spacing: 16,
        children: [
          YaruListTile(
            leading: Icon(
              isConnected ? YaruIcons.ok_simple : YaruIcons.cloud,
            ),
            title: Text(
              isConnected
                  ? (connectedTvName ?? 'Connected')
                  : 'No Active TV Connection',
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
              title: const Text('TV Do Not Disturb (DND)'),
              subtitle: const Text('Mute all notification popups on TV'),
              trailing: YaruSwitch(
                value: tvDndEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).setTvDnd(val);
                },
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isConnected) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(connectorProvider.notifier).disconnect();
                  },
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
                  onPressed: () {
                    ref.read(connectorProvider.notifier).startScanning();
                  },
                  icon: const Icon(YaruIcons.search),
                  label: const Text('Scan Again'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
