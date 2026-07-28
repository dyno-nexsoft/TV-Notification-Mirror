import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../widgets/filters/overlay_settings_card.dart';
import 'phone_app_filters_screen.dart';

/// The Settings page — notification preferences, TV overlay display options,
/// per-app filters, and a support section.
class PhoneSettingsScreen extends ConsumerWidget {
  const PhoneSettingsScreen({super.key, required this.onAddCustomApp});

  final VoidCallback onAddCustomApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value;
    final notifier = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          YaruSection(
            headline: const Text('NOTIFICATION PREFERENCES'),
            child: Column(
              children: [
                YaruSwitchListTile(
                  title: const Text('Mirror Phone Notifications'),
                  subtitle: const Text('Master switch for all TV mirroring'),
                  value: settings?.masterMirrorEnabled ?? true,
                  onChanged: notifier.setMasterMirrorEnabled,
                ),
                const Divider(),
                YaruSwitchListTile(
                  secondary: const Icon(YaruIcons.headset),
                  title: const Text('Incoming Calls'),
                  value: settings?.callNotificationsEnabled ?? true,
                  onChanged: notifier.setCallNotificationsEnabled,
                ),
                YaruSwitchListTile(
                  secondary: const Icon(YaruIcons.chat_bubble),
                  title: const Text('Text Messages'),
                  value: settings?.textNotificationsEnabled ?? true,
                  onChanged: notifier.setTextNotificationsEnabled,
                ),
                YaruSwitchListTile(
                  secondary: const Icon(YaruIcons.notification),
                  title: const Text('Other Notifications'),
                  value: settings?.otherNotificationsEnabled ?? true,
                  onChanged: notifier.setOtherNotificationsEnabled,
                ),
              ],
            ),
          ),
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
          const SupportSection(),
        ],
      ),
    );
  }
}
