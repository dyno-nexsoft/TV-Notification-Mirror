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
    final connectorState = ref.watch(connectorProvider);
    final asyncSettings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final iconCache = ref.watch(filtersProvider).value?.iconCache ?? {};
    final isConnected = connectorState.isConnected;
    final masterMirrorEnabled =
        asyncSettings.value?.masterMirrorEnabled ?? true;
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
            child: IntrinsicHeight(
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: YaruIcons.send,
                      label: 'Send Test\nNotification',
                      onTap: () => _sendTestNotification(ref),
                    ),
                  ),
                  Expanded(
                    child: _QuickActionCard(
                      icon: YaruIcons.notification,
                      label: 'Mirror Phone\nNotifications',
                      trailing: YaruSwitch(
                        value: masterMirrorEnabled,
                        onChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .setMasterMirrorEnabled(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
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
                    child:
                        Center(child: Text('No notifications captured yet.')),
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

/// A single square quick-action tile shown in a 2-column grid on Home,
/// matching the mockup's "Quick Actions" layout.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon),
                  if (trailing != null) trailing!,
                ],
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
