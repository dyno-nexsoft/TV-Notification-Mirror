import 'dart:typed_data';
import 'package:shared/shared.dart';
import 'history_item_card.dart';

/// The History tab — displays the last 50 received notifications.
class HistoryTab extends StatelessWidget {
  const HistoryTab({
    super.key,
    required this.history,
    required this.iconCache,
  });
  final List<NotificationItem> history;
  final Map<String, Uint8List?> iconCache;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              YaruIcons.history,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications captured yet.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New notifications will appear here.',
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return HistoryItemCard(
          item: history[index],
          iconCache: iconCache,
        );
      },
    );
  }
}
