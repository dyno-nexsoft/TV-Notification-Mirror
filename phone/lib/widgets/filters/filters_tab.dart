import 'dart:typed_data';

import 'package:shared/shared.dart';

import '../../services/filter_service.dart';
import 'app_filter_tile.dart';
import 'keyword_filter_card.dart';
import 'overlay_settings_card.dart';
import 'quiet_hours_card.dart';

/// The Filters tab — contains quiet hours, keyword blockers, overlay settings,
/// and a searchable list of per-app notification toggles using Yaru UI.
class FiltersTab extends StatefulWidget {
  const FiltersTab({
    super.key,
    required this.settings,
    required this.appFilters,
    required this.installedPresets,
    required this.iconCache,
    required this.onSettingsChanged,
    required this.onFilterChanged,
    required this.onAddCustomApp,
  });
  final AppSettings settings;
  final Map<String, bool> appFilters;
  final List<AppPreset> installedPresets;
  final Map<String, Uint8List?> iconCache;
  final ValueChanged<AppSettings> onSettingsChanged;
  final void Function(String pkg, bool value) onFilterChanged;
  final VoidCallback onAddCustomApp;

  @override
  State<FiltersTab> createState() => _FiltersTabState();
}

class _FiltersTabState extends State<FiltersTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final customApps = widget.appFilters.keys
        .where(
            (pkg) => !widget.installedPresets.any((app) => app.pkg == pkg))
        .map((pkg) => AppPreset(
              pkg: pkg,
              name: NotificationItem.getAppName(pkg),
            ))
        .toList();

    final allApps = [...widget.installedPresets, ...customApps];

    final filteredApps = allApps.where((app) {
      final name = app.name.toLowerCase();
      final pkg = app.pkg.toLowerCase();
      return name.contains(_searchQuery) || pkg.contains(_searchQuery);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuietHoursCard(
            settings: widget.settings,
            onChanged: widget.onSettingsChanged,
          ),
          KeywordFilterCard(
            settings: widget.settings,
            onChanged: widget.onSettingsChanged,
          ),
          OverlaySettingsCard(
            settings: widget.settings,
            onChanged: widget.onSettingsChanged,
          ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'App Filters (${filteredApps.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onAddCustomApp,
                  icon: const Icon(YaruIcons.plus),
                  label: const Text('Add Package'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: YaruSearchField(
              hintText: 'Search apps...',
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
              final isEnabled = widget.appFilters[pkg] ?? true;

              return AppFilterTile(
                packageName: pkg,
                appName: name,
                isEnabled: isEnabled,
                iconCache: widget.iconCache,
                onToggle: (val) => widget.onFilterChanged(pkg, val),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
