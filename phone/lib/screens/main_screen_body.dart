part of 'main_screen.dart';

/// Composes the bottom navigation bar and the active page view.
/// Consumes Riverpod state directly to avoid prop-drilling parameter lists.
class _MainScreenBody extends ConsumerWidget {
  const _MainScreenBody({
    required this.onManualConnect,
    required this.onPairDevice,
    required this.onAddCustomApp,
    required this.onScanQr,
  });

  final VoidCallback onManualConnect;
  final ValueChanged<TVDevice> onPairDevice;
  final VoidCallback onAddCustomApp;
  final VoidCallback onScanQr;

  void _sendTestNotification(WidgetRef ref) {
    final testItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: 'com.dyno.tv_notification_mirror.phone',
      appName: MirrorProtocol.appName,
      title: 'Jane Doe',
      text: 'Hello from your ${MirrorProtocol.appName} app! 📺✨',
      postTime: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(historyProvider.notifier).addNotification(testItem);
    ref.read(connectorProvider.notifier).sendNotification(testItem);
    AlertSoundService.playAlertSound(
      ref.read(settingsProvider).value?.alertSoundUri,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(permissionProvider);
    final navPage = ref.watch(phoneNavIndexProvider);
    final useRail = ResponsiveHelper.useSideNav(context);

    ref.listen<ToastData?>(appToastProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final useSideNav = ResponsiveHelper.useSideNav(context);
    final screens = <Widget>[
      const PhoneHomeScreen(),
      const PhoneAlertsScreen(),
      PhoneDevicesScreen(
        onSendTest: () => _sendTestNotification(ref),
        onManualConnect: onManualConnect,
        onPairDevice: onPairDevice,
        onScanQr: onScanQr,
      ),
      PhoneSettingsScreen(onAddCustomApp: onAddCustomApp),
    ];
    final bodyContent = Column(
      children: [
        if (hasPermissionAsync.value == false)
          PermissionBanner(
            notifier: ref.read(permissionProvider.notifier),
          ),
        Expanded(
          child: useSideNav
              ? Center(
                  child: SizedBox(
                    width: ResponsiveHelper.maxContentWidth(context),
                    child: IndexedStack(
                      index: navPage.index,
                      children: screens,
                    ),
                  ),
                )
              : IndexedStack(
                  index: navPage.index,
                  children: screens,
                ),
        ),
      ],
    );

    if (useRail) {
      return Scaffold(
        appBar: AppBar(title: const Text(MirrorProtocol.appName)),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navPage.index,
              onDestinationSelected: (index) => ref
                  .read(phoneNavIndexProvider.notifier)
                  .select(PhoneNavPage.values[index]),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(YaruIcons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(YaruIcons.notification), label: Text('Alerts')),
                NavigationRailDestination(icon: Icon(YaruIcons.computer), label: Text('Devices')),
                NavigationRailDestination(icon: Icon(YaruIcons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(MirrorProtocol.appName),
      ),
      body: bodyContent,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navPage.index,
        onDestinationSelected: (index) => ref
            .read(phoneNavIndexProvider.notifier)
            .select(PhoneNavPage.values[index]),
        destinations: const [
          NavigationDestination(icon: Icon(YaruIcons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(YaruIcons.notification), label: 'Alerts'),
          NavigationDestination(
              icon: Icon(YaruIcons.computer), label: 'Devices'),
          NavigationDestination(
              icon: Icon(YaruIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
