import 'package:shared/shared.dart';
import '../../services/connector_service.dart';

/// A single Yaru tile representing a discovered TV device in the network list.
class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    required this.onPair,
  });
  final TVDevice device;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: YaruListTile(
        leading: const Icon(YaruIcons.computer),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${device.ip}:${device.port}'),
        trailing: ElevatedButton(
          onPressed: onPair,
          child: const Text('Pair'),
        ),
      ),
    );
  }
}
