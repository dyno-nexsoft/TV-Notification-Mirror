import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import 'app_filter_tile.dart';
import 'keyword_filter_card.dart';
import 'overlay_settings_card.dart';
import 'quiet_hours_card.dart';

/// The Filters tab — contains quiet hours, keyword blockers, overlay settings,
/// and a searchable list of per-app notification toggles using Yaru UI.
class FiltersTab extends ConsumerStatefulWidget {
  const FiltersTab({
    super.key,
    required this.onAddCustomApp,
  });

  final VoidCallback onAddCustomApp;

  @override
  ConsumerState<FiltersTab> createState() => _FiltersTabState();
}

class _FiltersTabState extends ConsumerState<FiltersTab> {
  var _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final asyncFilters = ref.watch(filtersProvider);

    return asyncFilters.when(
        loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
        error: (e, st) => Center(child: Text('Error loading filters: $e')),
        data: (filtersState) {
          final appFilters = filtersState.appFilters;
          final installedPresets = filtersState.installedPresets;
          final iconCache = filtersState.iconCache;

          final customApps = appFilters.keys
              .where((pkg) => !installedPresets.any((app) => app.pkg == pkg))
              .map((pkg) => AppPreset(
                    pkg: pkg,
                    name: NotificationItem.getAppName(pkg),
                  ))
              .toList();

          final allApps = [...installedPresets, ...customApps];

          final filteredApps = allApps.where((app) {
            final name = app.name.toLowerCase();
            final pkg = app.pkg.toLowerCase();
            return name.contains(_searchQuery) || pkg.contains(_searchQuery);
          }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                const QuietHoursCard(),
                const KeywordFilterCard(),
                const OverlaySettingsCard(),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('App Filters (${filteredApps.length})'),
                      OutlinedButton.icon(
                        onPressed: widget.onAddCustomApp,
                        icon: const Icon(YaruIcons.plus),
                        label: const Text('Add Package'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: YaruSearchField(
                    hintText: 'Search apps...',
                    autofocus: false,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    final pkg = app.pkg;
                    final name = app.name;
                    final isEnabled = appFilters[pkg] ?? true;

                    return AppFilterTile(
                      packageName: pkg,
                      appName: name,
                      isEnabled: isEnabled,
                      iconCache: iconCache,
                      onToggle: (val) {
                        ref.read(filtersProvider.notifier).saveFilter(pkg, val);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}
