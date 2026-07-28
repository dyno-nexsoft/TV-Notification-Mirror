part of 'tv_home_screen.dart';

/// Blocks normal use until the overlay/notification permissions this app
/// needs are granted, surfacing whichever is still missing.
class _PermissionWarningBanner extends ConsumerWidget {
  const _PermissionWarningBanner({required this.permissions});

  final TvPermissionsState permissions;

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
              onPressed: () async {
                if (missingOverlay) {
                  await OverlayService.requestPermission();
                } else {
                  await OverlayService.requestNotificationPermission();
                }
                if (context.mounted) {
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
