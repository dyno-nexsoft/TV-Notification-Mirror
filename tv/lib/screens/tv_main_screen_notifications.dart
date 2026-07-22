part of 'tv_main_screen.dart';

/// Right sub-column of the TV dashboard: a scrolling feed of recently
/// mirrored notifications, newest first.
class _RecentNotificationsPanel extends StatelessWidget {
  const _RecentNotificationsPanel({
    required this.notificationHistory,
    required this.primaryColor,
  });

  final List<dynamic> notificationHistory;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: notificationHistory.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có thông báo nào.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
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

  final dynamic item;
  final Color primaryColor;

  String get _timeLabel {
    final timestamp = item['timestamp'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? '';
    final text = item['text'] ?? '';
    final appIconBase64 = item['appIcon'] as String?;

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
              : Icon(
                  YaruIcons.notification,
                  color: primaryColor,
                  size: 22,
                ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _timeLabel,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
