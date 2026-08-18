part of 'tv_home_screen.dart';

/// Package this app is installed under — used in the ADB grant commands shown
/// on devices (e.g. Fire TV) that have no permission-settings UI.
const _packageName = 'com.dyno.tv_notification_mirror.tv';

/// Blocks normal use until the overlay/notification permissions this app
/// needs are granted, surfacing whichever is still missing.
class _PermissionWarningBanner extends ConsumerWidget {
  const _PermissionWarningBanner({required this.permissions});

  final TvPermissionsState permissions;

  Future<void> _grantOverlay(BuildContext context, WidgetRef ref) async {
    final opened = await OverlayService.requestPermission();
    if (!opened && context.mounted) {
      await AdbInstructionsDialog.show(
        context,
        title: 'Grant overlay permission via ADB',
        message: 'This device has no "Display over other apps" settings '
            'screen. Enable Developer Options → ADB debugging on the TV, then '
            'run these commands from a computer on the same network:',
        steps: [
          'adb connect <DEVICE_IP>:5555',
          'adb shell appops set $_packageName SYSTEM_ALERT_WINDOW allow',
        ],
      );
    }
    if (context.mounted) {
      ref.read(tvPermissionsProvider.notifier).checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missingOverlay = !permissions.hasOverlayPermission;
    final message = missingOverlay
        ? 'This application requires Overlay Permission to display '
              'notifications over other apps.'
        : 'This application requires Notification Permission to run '
              'background connectivity.';
    final buttonLabel = missingOverlay
        ? 'Grant Overlay Permission'
        : 'Grant Notification Permission';

    return YaruSection(
      headline: const Row(
        spacing: 8,
        children: [Icon(YaruIcons.warning), Text('Permission Needed')],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(message),
            FilledButton.icon(
              onPressed: () {
                if (missingOverlay) {
                  _grantOverlay(context, ref);
                } else {
                  OverlayService.requestNotificationPermission();
                  ref.read(tvPermissionsProvider.notifier).checkPermissions();
                }
              },
              icon: const Icon(YaruIcons.external_link),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
