part of 'tv_settings_screen.dart';

/// NOTIFICATIONS section: per-type filters (real — enforced server-side by
/// category), alert sound, anchor position, and display duration (all real,
/// applied by the TV regardless of what the phone sends).
class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection({required this.settings});

  final TvSettings settings;

  bool get _allEnabled =>
      settings.callNotificationsEnabled &&
      settings.textNotificationsEnabled &&
      settings.imagePreviewsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvSettingsProvider.notifier);

    return YaruSection(
      headline: Row(
        children: [
          const Expanded(child: Text('NOTIFICATIONS')),
          const Text('Master Switch'),
          YaruSwitch(
            value: _allEnabled,
            onChanged: (value) => notifier.setAllNotificationTypes(value),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              children: [
                YaruSwitchListTile(
                  title: const Text('Call Notifications'),
                  value: settings.callNotificationsEnabled,
                  onChanged: (v) =>
                      notifier.setCallNotificationsEnabled(v),
                ),
                YaruSwitchListTile(
                  title: const Text('Text Messages'),
                  value: settings.textNotificationsEnabled,
                  onChanged: (v) =>
                      notifier.setTextNotificationsEnabled(v),
                ),
                YaruSwitchListTile(
                  title: const Text('Image Previews'),
                  value: settings.imagePreviewsEnabled,
                  onChanged: (v) => notifier.setImagePreviewsEnabled(v),
                ),
                YaruListTile(
                  leading: const Icon(YaruIcons.notification),
                  title: const Text('Alert Sound'),
                  trailing: Text(
                    settings.alertSoundUri == 'silent'
                        ? 'Silent'
                        : 'Standard Ping',
                  ),
                  onTap: () async {
                    final uri = await OverlayService.pickAlertSound();
                    if (uri != null) {
                      await notifier.setAlertSoundUri(uri);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Display Duration: ${settings.overlayDurationSeconds} seconds',
                  ),
                ),
                Slider(
                  value: settings.overlayDurationSeconds.toDouble(),
                  min: 3,
                  max: 15,
                  divisions: 12,
                  onChanged: (v) =>
                      notifier.setOverlayDurationSeconds(v.round()),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Anchor Position'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnchorPositionPicker(
                    value: settings.anchorPosition,
                    onChanged: notifier.setAnchorPosition,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
