import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../helpers/responsive_helper.dart';
import '../../providers/debug_log_provider.dart';
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

    final hp = ResponsiveHelper.horizontalPadding(context);
    final sp = ResponsiveHelper.spacing(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: ResponsiveHelper.verticalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: sp,
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: const Text('Theme'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: ThemeModeSelector(
                    value: settings?.themeMode ?? ThemeMode.dark,
                    onChanged: (mode) =>
                        ref.read(settingsProvider.notifier).setThemeMode(mode),
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
          YaruSection(
            headline: const Text('DEBUG'),
            child: Consumer(
              builder: (context, ref, _) {
                final logs = ref.watch(debugLogProvider);
                return DebugLogListTile(
                  logs: logs,
                  onClear: () => ref.read(debugLogProvider.notifier).clear(),
                  subtitle: 'Connection & notification pipeline logs',
                );
              },
            ),
          ),
          const SupportSection(),
        ],
      ),
    );
  }
}
