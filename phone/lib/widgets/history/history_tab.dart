import 'dart:typed_data';
import 'package:shared/shared.dart';
import 'history_item_card.dart';

/// The History tab — displays the last 50 received notifications.
class HistoryTab extends StatelessWidget {
  final List<NotificationItem> history;
  final Map<String, Uint8List?> iconCache;

  const HistoryTab({
    super.key,
    required this.history,
    required this.iconCache,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No notifications captured yet.',
          style: TextStyle(color: Colors.grey),
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
