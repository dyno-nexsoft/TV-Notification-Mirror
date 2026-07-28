import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_settings_provider.dart';
import '../../services/overlay_service.dart';
import '../../services/tv_settings_service.dart';
import '../../widgets/page_header.dart';

part 'tv_settings_general.dart';
part 'tv_settings_display.dart';
part 'tv_settings_notifications.dart';

/// Settings page: General/Display/Notifications/Support sections.
class TvSettingsScreen extends ConsumerWidget {
  const TvSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(tvSettingsProvider);

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
          _NotificationsSection(settings: settings),
          const SupportSection(),
        ],
      ),
    );
  }
}
