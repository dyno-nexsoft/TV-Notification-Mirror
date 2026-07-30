import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../services/alert_sound_service.dart';
import 'phone_app_filters_screen.dart';

String _alertSoundLabel(String? uri) {
  if (uri == null) return 'Default';
  if (uri == 'silent') return 'Silent';
  try {
    final decoded = Uri.decodeComponent(uri.split('/').last);
    if (decoded.length > 30) return '${decoded.substring(0, 27)}...';
    return decoded;
  } catch (_) {
    return uri;
  }
}

/// The Settings page — notification preferences, TV overlay display options,
/// per-app filters, and a support section.
class PhoneSettingsScreen extends ConsumerWidget {
  const PhoneSettingsScreen({super.key, required this.onAddCustomApp});

  final VoidCallback onAddCustomApp;

  Future<void> _pickAlertSound(WidgetRef ref) async {
    final uri = await AlertSoundService.pickAlertSound();
    if (uri != null) {
      await ref.read(settingsProvider.notifier).setAlertSoundUri(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          YaruSection(
            headline: const Text('ALERT SOUND'),
            child: YaruListTile(
              leading: const Icon(YaruIcons.headset),
              title: const Text('Test Notification Sound'),
              subtitle: Text(_alertSoundLabel(settings?.alertSoundUri)),
              trailing: const Icon(YaruIcons.pan_end),
              onTap: () => _pickAlertSound(ref),
            ),
          ),
          YaruSection(
            headline: const Text('APPEARANCE'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Theme'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ],
                    selected: {settings?.themeMode ?? ThemeMode.dark},
                    onSelectionChanged: (selection) =>
                        ref.read(settingsProvider.notifier).setThemeMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
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
