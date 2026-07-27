import 'dart:convert';

import 'package:shared/shared.dart';

/// A single row in the notification history feed: app icon/badge, title,
/// message preview, and a relative timestamp.
class NotificationHistoryTile extends StatelessWidget {
  const NotificationHistoryTile({super.key, required this.item});

  final NotificationItem item;

  String get _relativeTime {
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(item.postTime));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 2) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appIconBase64 = item.appIcon;

    // Card (not YaruBanner) since this tile's height varies with content and
    // YaruBanner always requests height: double.infinity internally.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: appIconBase64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(appIconBase64),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  : const Icon(YaruIcons.notification),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          item.appName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Spacer(),
                      Text(_relativeTime, style: theme.textTheme.labelSmall),
                    ],
                  ),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
