import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import '../../services/connector_service.dart';
import '../../services/filter_service.dart';
import 'status_card.dart';
import 'device_list_tile.dart';

/// The Connect tab — shows connection status, discovered devices list,
/// and manual IP connect option using Yaru UI elements.
class ConnectTab extends StatelessWidget {
  final bool isConnected;
  final List<TVDevice> discoveredDevices;
  final String? connectedTvName;
  final bool tvDndEnabled;
  final AppSettings settings;
  final ConnectorService connector;
  final VoidCallback onSendTest;
  final VoidCallback onManualConnect;
  final ValueChanged<bool> onDndChanged;
  final ValueChanged<TVDevice> onPairDevice;

  const ConnectTab({
    super.key,
    required this.isConnected,
    required this.discoveredDevices,
    required this.connectedTvName,
    required this.tvDndEnabled,
    required this.settings,
    required this.connector,
    required this.onSendTest,
    required this.onManualConnect,
    required this.onDndChanged,
    required this.onPairDevice,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusCard(
            isConnected: isConnected,
            connectedTvName: connectedTvName,
            tvDndEnabled: tvDndEnabled,
            settings: settings,
            connector: connector,
            onScanAgain: () => connector.startScanning(),
            onSendTest: onSendTest,
            onDndChanged: onDndChanged,
          ),
          const SizedBox(height: 16),
          if (!isConnected) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onManualConnect,
              icon: Icon(YaruIcons.external_link),
              label: const Text('Connect with IP Address'),
            ),
            const SizedBox(height: 24),
            YaruSection(
              headline: Text(
                'Available TVs (${discoveredDevices.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Scanning for TV devices in local Wi-Fi network...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
