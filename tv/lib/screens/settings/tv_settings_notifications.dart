part of 'tv_settings_screen.dart';

/// NOTIFICATIONS section: per-type filters (real — enforced server-side by
/// category), alert sound, anchor position, and display duration (all real,
/// applied by the TV regardless of what the phone sends). The toggles/alert
/// sound and the position/duration controls are shared, identical widgets
/// with the Phone app's own Notification Preferences / TV Overlay Settings.
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
            child: NotificationCategoryToggles(
              callEnabled: settings.callNotificationsEnabled,
              onCallChanged: notifier.setCallNotificationsEnabled,
              textEnabled: settings.textNotificationsEnabled,
              onTextChanged: notifier.setTextNotificationsEnabled,
              imagePreviewsEnabled: settings.imagePreviewsEnabled,
              onImagePreviewsChanged: notifier.setImagePreviewsEnabled,
              alertSoundLabel:
                  settings.alertSoundUri == 'silent'
                      ? 'Silent'
                      : 'Standard Ping',
              onPickAlertSound: () async {
                final uri = await OverlayService.pickAlertSound();
                if (uri != null) {
                  await notifier.setAlertSoundUri(uri);
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OverlayPositionDurationSettings(
                position: settings.anchorPosition,
                onPositionChanged: notifier.setAnchorPosition,
                durationSeconds: settings.overlayDurationSeconds,
                onDurationChanged: notifier.setOverlayDurationSeconds,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
