import 'package:shared/shared.dart';

/// A TV-optimised paired device card using Yaru UI widgets.
class PairedDeviceCard extends StatelessWidget {
  const PairedDeviceCard({
    super.key,
    required this.deviceName,
    required this.ip,
    required this.isOnline,
    required this.onRemove,
  });

  final String deviceName;
  final String ip;
  final bool isOnline;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: YaruListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(YaruIcons.phone),
        ),
        title: Row(
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                deviceName,
                maxLines: 1,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.greenAccent : Colors.grey,
              ),
            ),
          ],
        ),
        subtitle: Text(
          isOnline ? ip : 'Offline',
        ),
        trailing: IconButton(
          icon: const Icon(YaruIcons.trash),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
