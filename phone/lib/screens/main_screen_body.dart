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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(permissionProvider);
    final navPage = ref.watch(phoneNavIndexProvider);

    ref.listen<ToastData?>(appToastProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(MirrorProtocol.appName),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(YaruIcons.refresh),
            onPressed: () {
              ref.read(permissionProvider.notifier).checkPermission();
              ref.read(connectorProvider.notifier).startScanning();
            },
            tooltip: 'Refresh / Scan',
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 8.0),
      ),
      body: Column(
        children: [
          if (hasPermissionAsync.value == false)
            PermissionBanner(
              notifier: ref.read(permissionProvider.notifier),
            ),
          Expanded(
            child: switch (navPage) {
              PhoneNavPage.home => const PhoneHomeScreen(),
              PhoneNavPage.alerts => const PhoneAlertsScreen(),
              PhoneNavPage.devices => PhoneDevicesScreen(
                  onSendTest: () => _sendTestNotification(ref),
                  onManualConnect: onManualConnect,
                  onPairDevice: onPairDevice,
                  onScanQr: onScanQr,
                ),
              PhoneNavPage.settings =>
                PhoneSettingsScreen(onAddCustomApp: onAddCustomApp),
            },
          ),
        ],
      ),
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
