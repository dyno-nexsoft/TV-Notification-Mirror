import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_nav_provider.dart';
import '../../providers/tv_providers.dart';
import '../../services/overlay_service.dart';
import '../../widgets/page_header.dart';

part 'tv_home_action_cards.dart';
part 'tv_home_dnd_section.dart';
part 'tv_home_permission_banner.dart';

/// Home page: quick actions, the master notification-receiving switch, and
/// the Do Not Disturb control with quick-duration presets.
class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvState = ref.watch(tvServiceStateProvider);
    final isDnd = tvState.isDnd;
    final permissions = ref.watch(tvPermissionsProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const PageHeader(title: 'Home'),
          if (permissions != null && !permissions.isFullyGranted)
            _PermissionWarningBanner(permissions: permissions),
          const _HomeActionCardsRow(),
          YaruSwitchListTile(
            title: const Text('Notification Receiving'),
            subtitle: const Text(
              'Receiving notifications from all connected devices',
            ),
            value: !isDnd,
            onChanged: (_) =>
                ref.read(tvServiceStateProvider.notifier).toggleDnd(),
          ),
          _DoNotDisturbSection(isDnd: isDnd),
        ],
      ),
    );
  }
}
