import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../widgets/filters/app_filter_tile.dart';

/// Full-page, searchable list of per-app notification mirror toggles,
/// reached from Settings > App Filters.
class PhoneAppFiltersScreen extends ConsumerStatefulWidget {
  const PhoneAppFiltersScreen({super.key, required this.onAddCustomApp});

  final VoidCallback onAddCustomApp;

  @override
  ConsumerState<PhoneAppFiltersScreen> createState() =>
      _PhoneAppFiltersScreenState();
}

class _PhoneAppFiltersScreenState extends ConsumerState<PhoneAppFiltersScreen> {
  var _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final asyncFilters = ref.watch(filtersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Filters'),
        actions: [
          IconButton(
            icon: const Icon(YaruIcons.plus),
            tooltip: 'Add Package',
            onPressed: widget.onAddCustomApp,
          ),
        ],
      ),
      body: asyncFilters.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: YaruSearchField(
                  hintText: 'Search apps...',
                  autofocus: false,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
