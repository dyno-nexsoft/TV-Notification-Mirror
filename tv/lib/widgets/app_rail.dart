import 'package:shared/shared.dart';

/// Branding header shown above the nav rail destinations: app icon, name,
/// and a standby/active status dot.
class AppRailHeader extends StatelessWidget {
  const AppRailHeader({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Row(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  YaruIcons.monitor,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const Text(MirrorProtocol.appName),
            ],
          ),
          Row(
            spacing: 6,
            children: [
              StatusDot(isOnline: isActive),
              Text(isActive ? 'Active' : 'Standby'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Footer shown below the nav rail destinations, identifying this TV device.
class RailDeviceFooter extends StatelessWidget {
  const RailDeviceFooter({super.key, required this.deviceLabel});

  final String deviceLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        spacing: 8,
        children: [
          const Icon(YaruIcons.computer),
          Flexible(
            child: Text(
              deviceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
