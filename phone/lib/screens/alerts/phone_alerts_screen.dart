import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../helpers/responsive_helper.dart';
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
    final theme = Theme.of(context);
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

    final hp = ResponsiveHelper.horizontalPadding(context);
    final useGrid = ResponsiveHelper.useGrid(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hp, ResponsiveHelper.verticalPadding(context), hp, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Alerts', style: theme.textTheme.titleLarge),
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
              : useGrid
                  ? GridView.builder(
                      padding: EdgeInsets.all(hp),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: hp,
                        mainAxisSpacing: hp,
                        childAspectRatio: 3.5,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => HistoryItemCard(
                        item: filtered[index],
                        iconCache: iconCache,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: hp),
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
