import 'package:shared/shared.dart';
import '../services/notification_service.dart';

/// Banner shown at the top of the screen when notification access is missing.
class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key, required this.notifier});

  final NotificationService notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 12,
        children: [
          const Icon(
            YaruIcons.warning,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(
                  'Notification Access Missing',
                ),
                Text(
                  'Mirroring requires permission to read phone notifications.',
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => notifier.openSettings(),
            child: const Text('Enable Access'),
          ),
        ],
      ),
    );
  }
}
