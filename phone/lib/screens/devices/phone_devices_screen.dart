import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../services/connector_service.dart';
import '../../widgets/connect/device_list_tile.dart';
import '../../widgets/connect/status_card.dart';

/// The Devices page — connection status, pairing entry points (QR/PIN/manual
/// IP), and the list of TVs discovered on the local network.
class PhoneDevicesScreen extends ConsumerWidget {
  const PhoneDevicesScreen({
    super.key,
    required this.onSendTest,
    required this.onManualConnect,
    required this.onPairDevice,
    required this.onScanQr,
  });

  final VoidCallback onSendTest;
  final VoidCallback onManualConnect;
  final ValueChanged<TVDevice> onPairDevice;
  final VoidCallback onScanQr;

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
          StatusCard(onSendTest: onSendTest),
          if (!isConnected) ...[
            YaruSection(
              headline: Text('Available TVs (${discoveredDevices.length})'),
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
            OutlinedButton.icon(
              onPressed: onScanQr,
              icon: const Icon(YaruIcons.scanner),
              label: const Text('Scan QR to Pair'),
            ),
            OutlinedButton.icon(
              onPressed: onManualConnect,
              icon: const Icon(YaruIcons.external_link),
              label: const Text('Connect with IP Address'),
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
