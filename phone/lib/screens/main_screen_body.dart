part of 'main_screen.dart';

/// Composes the tab navigation bar and the active tab view.
/// Consumes Riverpod state directly to avoid prop-drilling parameter lists.
class _MainScreenBody extends ConsumerWidget {
  const _MainScreenBody({
    required this.onManualConnect,
    required this.onPairDevice,
    required this.onAddCustomApp,
  });

  final VoidCallback onManualConnect;
  final ValueChanged<TVDevice> onPairDevice;
  final VoidCallback onAddCustomApp;

  void _sendTestNotification(WidgetRef ref) {
    final testItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: 'com.dyno.tv_notification_mirror.phone',
      appName: 'TV Mirror',
      title: 'Jane Doe',
      text: 'Hello from your TV Mirror app! 📺✨',
      postTime: DateTime.now().millisecondsSinceEpoch,
    );
    ref.read(historyProvider.notifier).addNotification(testItem);
    ref.read(connectorProvider.notifier).sendNotification(testItem);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermissionAsync = ref.watch(permissionProvider);

    ref.listen<ToastData?>(appToastProvider, (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TV Mirror'),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(YaruIcons.refresh),
                onPressed: () {
                  ref.read(permissionProvider.notifier).checkPermission();
                  ref.read(connectorProvider.notifier).startScanning();
                },
                tooltip: 'Refresh / Scan',
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(YaruIcons.computer), text: 'Connect'),
              Tab(icon: Icon(YaruIcons.pen), text: 'Apps'),
              Tab(icon: Icon(YaruIcons.history), text: 'History'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (hasPermissionAsync.value == false)
              PermissionBanner(
                notifier: ref.read(notificationServiceProvider),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  ConnectTab(
                    onSendTest: () => _sendTestNotification(ref),
                    onManualConnect: onManualConnect,
                    onPairDevice: onPairDevice,
                  ),
                  FiltersTab(
                    onAddCustomApp: onAddCustomApp,
                  ),
                  const HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
