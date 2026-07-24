import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../services/connector_service.dart';
import 'device_list_tile.dart';
import 'status_card.dart';

/// The Connect tab — shows connection status, discovered devices list,
/// and manual IP connect option using Yaru UI elements.
class ConnectTab extends ConsumerWidget {
  const ConnectTab({
    super.key,
    required this.onSendTest,
    required this.onManualConnect,
    required this.onPairDevice,
  });

  final VoidCallback onSendTest;
  final VoidCallback onManualConnect;
  final ValueChanged<TVDevice> onPairDevice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectorState = ref.watch(connectorProvider);
    final isConnected = connectorState.isConnected;
    final discoveredDevices = connectorState.discoveredDevices;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          StatusCard(
            onSendTest: onSendTest,
          ),
          if (!isConnected) ...[
            OutlinedButton.icon(
              onPressed: onManualConnect,
              icon: const Icon(YaruIcons.external_link),
              label: const Text('Connect with IP Address'),
            ),
            YaruSection(
              headline: Text(
                'Available TVs (${discoveredDevices.length})',
              ),
              child: discoveredDevices.isEmpty
                  ? const _ScanningCard()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final dev = discoveredDevices[index];
                        return DeviceListTile(
                          device: dev,
                          onPair: () => onPairDevice(dev),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanningCard extends StatelessWidget {
  const _ScanningCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 24,
        children: [
          YaruCircularProgressIndicator(),
          Text(
            'Scanning for TV devices in local Wi-Fi network...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
