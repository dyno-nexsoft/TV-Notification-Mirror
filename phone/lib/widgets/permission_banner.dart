import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import '../services/notification_service.dart';

/// Banner shown at the top of the screen when notification access is missing.
class PermissionBanner extends StatelessWidget {
  final NotificationService notifier;

  const PermissionBanner({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.15),
        border: Border.all(color: errorColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(YaruIcons.warning, color: errorColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notification access required to read and mirror phone notifications.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => notifier.openSettings(),
            child: const Text(
              'Enable',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
