import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../widgets/filters/keyword_filter_card.dart';
import '../../widgets/filters/overlay_settings_card.dart';
import '../../widgets/filters/quiet_hours_card.dart';
import 'phone_app_filters_screen.dart';

part 'phone_settings_account.dart';
part 'phone_settings_support.dart';

/// The Settings page — notification preferences, TV overlay display options,
/// per-app filters, and stub account/support sections.
class PhoneSettingsScreen extends ConsumerWidget {
  const PhoneSettingsScreen({super.key, required this.onAddCustomApp});

  final VoidCallback onAddCustomApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final masterMirrorEnabled = asyncSettings.value?.masterMirrorEnabled ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const _AccountSection(),
          YaruSection(
            headline: const Text('NOTIFICATION PREFERENCES'),
            child: YaruSwitchListTile(
              title: const Text('Mirror Phone Notifications'),
              subtitle: const Text('Master switch for all TV mirroring'),
              value: masterMirrorEnabled,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setMasterMirrorEnabled(val);
              },
            ),
          ),
          const QuietHoursCard(),
          const KeywordFilterCard(),
          const OverlaySettingsCard(),
          YaruSection(
            headline: const Text('APP FILTERS'),
            child: YaruListTile(
              leading: const Icon(YaruIcons.pen),
              title: const Text('Per-App Notification Filters'),
              trailing: const Icon(YaruIcons.pan_end),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PhoneAppFiltersScreen(onAddCustomApp: onAddCustomApp),
                ),
              ),
            ),
          ),
          const _SupportSection(),
        ],
      ),
    );
  }
}
