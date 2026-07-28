import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/tv_nav_provider.dart';
import '../../providers/tv_providers.dart';
import '../../widgets/dashed_border_box.dart';
import '../../widgets/page_header.dart';
import '../../widgets/paired_device_card.dart';

part 'tv_manage_devices_dialogs.dart';

/// Manage Devices page: a grid of paired phones with rename/remove actions,
/// an "add device via QR" shortcut, and a banner linking to Pair Device.
class TvManageDevicesScreen extends ConsumerWidget {
  const TvManageDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvState = ref.watch(tvServiceStateProvider);
    final pairedClients = tvState.pairedClients;
    final activeTokens = tvState.activeTokens;
    final notifier = ref.read(tvServiceStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          const PageHeader(
            title: 'Manage Devices',
            subtitle: 'Control and monitor your connected mobile devices.',
          ),
          Expanded(
            child: pairedClients.isEmpty
              ? const _EmptyDevices()
              : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 340,
                          mainAxisExtent: 160,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: pairedClients.length + 1,
                    itemBuilder: (context, index) {
                      if (index == pairedClients.length) {
                        return _AddDeviceCard(
                          onTap: () => ref
                              .read(tvNavIndexProvider.notifier)
                              .select(TvNavPage.pairDevice),
                        );
                      }
                      final client = pairedClients[index];
                      final token = client.token ?? '';
                      return PairedDeviceCard(
                        deviceName: client.name,
                        isOnline: activeTokens.contains(token),
                        lastSyncedAt: client.lastSyncedAt,
                        onRename: () => showDialog(
                          context: context,
                          builder: (dialogCtx) => _RenameDeviceDialog(
                            currentName: client.name,
                            onConfirm: (newName) {
                              Navigator.pop(dialogCtx);
                              notifier.renameClient(token, newName);
                            },
                          ),
                        ),
                        onRemove: () => showDialog(
                          context: context,
                          builder: (dialogCtx) => _RemoveDeviceDialog(
                            deviceName: client.name,
                            onConfirm: () {
                              Navigator.pop(dialogCtx);
                              notifier.removeClient(token);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // YaruBanner always requests height: double.infinity internally, so
          // it needs a bounded-height ancestor when placed in a Column.
          SizedBox(
            height: 96,
            child: YaruBanner.tile(
              icon: const Icon(YaruIcons.phone),
              title: const Text('Need to connect another device?'),
              subtitle: const Text(
                'Sync your phone or tablet instantly to start receiving '
                'notifications on the big screen.',
              ),
              onTap: () => ref
                  .read(tvNavIndexProvider.notifier)
                  .select(TvNavPage.pairDevice),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddDeviceCard extends StatelessWidget {
  const _AddDeviceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DashedBorderBox(
        color: theme.colorScheme.outline,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [Icon(YaruIcons.plus), Text('Add device via QR code')],
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [Icon(YaruIcons.phone), Text('No devices paired yet.')],
      ),
    );
  }
}
