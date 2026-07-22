import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import '../../services/connector_service.dart';

/// A single Yaru tile representing a discovered TV device in the network list.
class DeviceListTile extends StatelessWidget {
  final TVDevice device;
  final VoidCallback onPair;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: YaruTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.15),
          child: Icon(YaruIcons.computer, color: primaryColor),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${device.ip}:${device.port}'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onPair,
          child: const Text('Pair'),
        ),
      ),
    );
  }
}
