import 'package:shared/shared.dart';
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
      child: YaruListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(YaruIcons.computer, color: primaryColor, size: 22),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${device.ip}:${device.port}'),
        trailing: YaruOptionButton(
          onPressed: onPair,
          child: const Text('Pair'),
        ),
      ),
    );
  }
}
