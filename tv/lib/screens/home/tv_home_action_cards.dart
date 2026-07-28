part of 'tv_home_screen.dart';

/// The two quick-action cards at the top of Home: jump to pairing a new
/// device, or to the devices already paired.
class _HomeActionCardsRow extends ConsumerWidget {
  const _HomeActionCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: BorderedActionCard(
            icon: Icons.qr_code_scanner,
            title: 'Pair New Device',
            subtitle: 'Scan QR to connect',
            onTap: () => ref
                .read(tvNavIndexProvider.notifier)
                .select(TvNavPage.pairDevice),
          ),
        ),
        Expanded(
          child: BorderedActionCard(
            icon: YaruIcons.phone,
            title: 'Manage Devices',
            subtitle: 'View connected devices',
            onTap: () => ref
                .read(tvNavIndexProvider.notifier)
                .select(TvNavPage.manageDevices),
          ),
        ),
      ],
    );
  }
}
