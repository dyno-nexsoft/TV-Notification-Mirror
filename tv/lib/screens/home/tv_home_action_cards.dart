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
          child: _HomeActionCard(
            icon: YaruIcons.scanner,
            title: 'Pair New Device',
            subtitle: 'Scan QR to connect',
            onTap: () => ref
                .read(tvNavIndexProvider.notifier)
                .select(TvNavPage.pairDevice),
          ),
        ),
        Expanded(
          child: _HomeActionCard(
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // YaruBanner always requests height: double.infinity internally, so it
    // needs a bounded-height ancestor — Row/Expanded alone won't provide one.
    return SizedBox(
      height: 96,
      child: YaruBanner.tile(
        onTap: onTap,
        icon: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
