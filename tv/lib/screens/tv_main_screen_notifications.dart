part of 'tv_main_screen.dart';

/// Right sub-column of the TV dashboard: a scrolling feed of recently
/// mirrored notifications, newest first.
class _RecentNotificationsPanel extends StatelessWidget {
  const _RecentNotificationsPanel({
    required this.notificationHistory,
    required this.primaryColor,
  });

  final List<NotificationItem> notificationHistory;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Text('Recent Notifications'),
        Expanded(
          child: notificationHistory.isEmpty
              ? const Center(
                  child: Text('No notifications yet.'),
                )
              : ListView.builder(
                  itemCount: notificationHistory.length,
                  itemBuilder: (context, index) => _NotificationHistoryTile(
                    item: notificationHistory[index],
                    primaryColor: primaryColor,
                  ),
                ),
        ),
      ],
    );
  }
}

/// A single row in the recent-notifications feed.
class _NotificationHistoryTile extends StatelessWidget {
  const _NotificationHistoryTile({
    required this.item,
    required this.primaryColor,
  });

  final NotificationItem item;
  final Color primaryColor;

  String get _timeLabel {
    final dt = DateTime.fromMillisecondsSinceEpoch(item.postTime);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    final text = item.text;
    final appIconBase64 = item.appIcon;

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
          child: appIconBase64 != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(appIconBase64),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(
                  YaruIcons.notification,
                ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _timeLabel,
        ),
      ),
    );
  }
}
