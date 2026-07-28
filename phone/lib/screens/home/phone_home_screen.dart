import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_nav_provider.dart';
import '../../providers/phone_providers.dart';
import '../../widgets/history/history_item_card.dart';

/// The Home page — connection summary, quick actions, and a preview of the
/// most recent mirrored notifications.
class PhoneHomeScreen extends ConsumerWidget {
  const PhoneHomeScreen({super.key});

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
    final connectorState = ref.watch(connectorProvider);
    final asyncSettings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final iconCache = ref.watch(filtersProvider).value?.iconCache ?? {};
    final isConnected = connectorState.isConnected;
    final masterMirrorEnabled = asyncSettings.value?.masterMirrorEnabled ?? true;
    final recent = history.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          YaruSection(
            headline: const Text('Connection'),
            child: YaruListTile(
              leading: Icon(
                isConnected ? YaruIcons.ok_simple : YaruIcons.cloud,
              ),
              title: Text(
                isConnected
                    ? (connectorState.connectedTvName ?? 'Connected')
                    : 'No Active TV Connection',
              ),
              subtitle: Text(
                isConnected
                    ? 'Notifications are being mirrored in real-time.'
                    : 'Go to Devices to scan or pair a TV.',
              ),
            ),
          ),
          YaruSection(
            headline: const Text('Quick Actions'),
            child: Column(
              children: [
                YaruSwitchListTile(
                  title: const Text('Mirror Phone Notifications'),
                  subtitle: const Text('Turn off to pause mirroring entirely'),
                  value: masterMirrorEnabled,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setMasterMirrorEnabled(val);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sendTestNotification(ref),
                          icon: const Icon(YaruIcons.go_next),
                          label: const Text('Send Test Notification'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          YaruSection(
            headline: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity'),
                TextButton(
                  onPressed: () => ref
                      .read(phoneNavIndexProvider.notifier)
                      .select(PhoneNavPage.alerts),
                  child: const Text('View All'),
                ),
              ],
            ),
            child: recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No notifications captured yet.')),
                  )
                : Column(
                    children: [
                      for (final item in recent)
                        HistoryItemCard(item: item, iconCache: iconCache),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
