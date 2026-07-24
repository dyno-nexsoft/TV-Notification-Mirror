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
        children: [
          Icon(
            YaruIcons.warning,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notification Access Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Access required to mirror phone notifications to TV.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => notifier.openSettings(),
            child: const Text('Enable Access'),
          ),
        ],
      ),
    );
  }
}
