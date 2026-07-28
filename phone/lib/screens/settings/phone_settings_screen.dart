import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';
import '../../services/alert_sound_service.dart';
import 'phone_app_filters_screen.dart';

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
                NotificationCategoryToggles(
                  callEnabled: settings?.callNotificationsEnabled ?? true,
                  onCallChanged: notifier.setCallNotificationsEnabled,
                  textEnabled: settings?.textNotificationsEnabled ?? true,
                  onTextChanged: notifier.setTextNotificationsEnabled,
                  imagePreviewsEnabled:
                      settings?.imagePreviewsEnabled ?? true,
                  onImagePreviewsChanged: notifier.setImagePreviewsEnabled,
                  alertSoundLabel:
                      settings?.alertSoundUri == 'silent'
                          ? 'Silent'
                          : 'Standard Ping',
                  onPickAlertSound: () => _pickAlertSound(ref),
                ),
              ],
            ),
          ),
          YaruSection(
            headline: const Row(
              spacing: 8,
              children: [
                Icon(YaruIcons.computer),
                Text('TV Overlay Settings'),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OverlayPositionDurationSettings(
                position: settings?.overlayPosition ?? MirrorProtocol.overlayTopRight,
                onPositionChanged: (val) {
                  if (settings == null) return;
                  notifier.updateSettings(settings.copyWith(overlayPosition: val));
                },
                durationSeconds: settings?.overlayDurationSeconds ?? 5,
                onDurationChanged: (val) {
                  if (settings == null) return;
                  notifier.updateSettings(
                    settings.copyWith(overlayDurationSeconds: val),
                  );
                },
                durationMin: 2,
              ),
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
