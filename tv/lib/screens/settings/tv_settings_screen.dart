import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_debug_log_provider.dart';
import '../../providers/tv_settings_provider.dart';
import '../../services/overlay_service.dart';
import '../../services/tv_settings_service.dart';
import '../../widgets/page_header.dart';

part 'tv_settings_general.dart';
part 'tv_settings_display.dart';

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

/// Settings page: General/Display/Notification Preferences/TV Overlay/
/// Support sections. The notification preferences and overlay settings
/// cards are shared, identical widgets with the Phone app's own settings.
class TvSettingsScreen extends ConsumerWidget {
  const TvSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tvSettingsProvider);
    final notifier = ref.read(tvSettingsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle:
                'Configure how ${MirrorProtocol.appName} behaves on your screen.',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              Expanded(child: _GeneralSection(settings: settings)),
              Expanded(child: _DisplaySection(settings: settings)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              Expanded(
                child: NotificationPreferencesCard(
                  callEnabled: settings.callNotificationsEnabled,
                  onCallChanged: notifier.setCallNotificationsEnabled,
                  textEnabled: settings.textNotificationsEnabled,
                  onTextChanged: notifier.setTextNotificationsEnabled,
                  imagePreviewsEnabled: settings.imagePreviewsEnabled,
                  onImagePreviewsChanged: notifier.setImagePreviewsEnabled,
                  alertSoundLabel: _alertSoundLabel(settings.alertSoundUri),
                  onPickAlertSound: () async {
                    final uri = await OverlayService.pickAlertSound();
                    if (uri != null) {
                      await notifier.setAlertSoundUri(uri);
                    }
                  },
                ),
              ),
              Expanded(
                child: TvOverlaySettingsCard(
                  position: settings.anchorPosition,
                  onPositionChanged: notifier.setAnchorPosition,
                  durationSeconds: settings.overlayDurationSeconds,
                  onDurationChanged: notifier.setOverlayDurationSeconds,
                ),
              ),
            ],
          ),
          YaruSection(
            headline: const Text('DEBUG'),
            child: Consumer(
              builder: (context, ref, _) {
                final logs = ref.watch(tvDebugLogProvider);
                return DebugLogListTile(
                  logs: logs,
                  onClear: () => ref.read(tvDebugLogProvider.notifier).clear(),
                  subtitle: 'Server, overlay & connection logs',
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
