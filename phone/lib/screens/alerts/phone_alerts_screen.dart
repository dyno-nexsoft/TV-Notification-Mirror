import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../widgets/history/history_item_card.dart';

/// The Alerts page — full mirrored-notification history with search and a
/// clear-all action.
class PhoneAlertsScreen extends ConsumerStatefulWidget {
  const PhoneAlertsScreen({super.key});

  @override
  ConsumerState<PhoneAlertsScreen> createState() => _PhoneAlertsScreenState();
}

class _PhoneAlertsScreenState extends ConsumerState<PhoneAlertsScreen> {
  var _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final iconCache = ref.watch(filtersProvider).value?.iconCache ?? {};

    final filtered = _searchQuery.isEmpty
        ? history
        : history.where((item) {
            final query = _searchQuery.toLowerCase();
            return item.title.toLowerCase().contains(query) ||
                item.text.toLowerCase().contains(query) ||
                item.appName.toLowerCase().contains(query);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Alerts'),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(historyProvider.notifier).clearHistory(),
                      icon: const Icon(YaruIcons.edit_clear),
                      label: const Text('Clear All'),
                    ),
                ],
              ),
              YaruSearchField(
                hintText: 'Search alerts...',
                autofocus: false,
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 12,
                    children: [
                      Icon(YaruIcons.history),
                      Text('No notifications captured yet.'),
                      Text('New notifications will appear here.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return HistoryItemCard(
                      item: filtered[index],
                      iconCache: iconCache,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
