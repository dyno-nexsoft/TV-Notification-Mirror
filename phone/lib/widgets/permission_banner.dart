import 'package:shared/shared.dart';
import '../services/notification_service.dart';

/// Banner shown at the top of the screen when notification access is missing, using native YaruBanner.
class PermissionBanner extends StatelessWidget {
  final NotificationService notifier;

  const PermissionBanner({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: YaruBanner(
        color: Colors.redAccent.withValues(alpha: 0.15),
        child: YaruListTile(
          leading: const Icon(YaruIcons.warning, color: Colors.redAccent),
          title: const Text('Notification Access Required'),
          subtitle: const Text(
            'Notification access is required to read and mirror phone notifications to TV.',
          ),
          trailing: YaruOptionButton(
            onPressed: () => notifier.openSettings(),
            child: const Text('Enable Access'),
          ),
        ),
      ),
    );
  }
}
