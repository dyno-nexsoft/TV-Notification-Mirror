import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_providers.dart';
import '../../widgets/notification_history_tile.dart';
import '../../widgets/page_header.dart';

/// History page: a scrolling feed of recently mirrored notifications,
/// newest first, with a Clear All action.
class TvHistoryScreen extends ConsumerWidget {
  const TvHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(tvServiceStateProvider).notificationHistory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          PageHeader(
            title: 'History',
            subtitle: 'Review recent alerts from your connected devices.',
            trailing: history.isEmpty
                ? null
                : OutlinedButton.icon(
                    onPressed: () => ref
                        .read(tvServiceStateProvider.notifier)
                        .clearHistory(),
                    icon: const Icon(YaruIcons.trash),
                    label: const Text('Clear All'),
                  ),
          ),
          Expanded(
            child: history.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        NotificationHistoryTile(item: history[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [Icon(YaruIcons.notification), Text('No notifications yet.')],
      ),
    );
  }
}
