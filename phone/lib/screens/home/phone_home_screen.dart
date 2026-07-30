import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../helpers/responsive_helper.dart';
import '../../providers/phone_nav_provider.dart';
import '../../providers/phone_providers.dart';
import '../../services/alert_sound_service.dart';
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
    AlertSoundService.playAlertSound(
      ref.read(settingsProvider).value?.alertSoundUri,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectorState = ref.watch(connectorProvider);
    final history = ref.watch(historyProvider);
    final iconCache = ref.watch(filtersProvider).value?.iconCache ?? {};
    final isConnected = connectorState.isConnected;
    final recent = history.take(3).toList();

    final hp = ResponsiveHelper.horizontalPadding(context);
    final vp = ResponsiveHelper.verticalPadding(context);
    final sp = ResponsiveHelper.spacing(context);
    final useGrid = ResponsiveHelper.useGrid(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: vp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: sp,
        children: [
          if (useGrid)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: sp,
              children: [
                Expanded(
                  child: YaruSection(
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
                ),
                Expanded(
                  child: YaruSection(
                    headline: const Text('Quick Actions'),
                    child: YaruListTile(
                      leading: const Icon(YaruIcons.send),
                      title: const Text('Send Test Notification'),
                      onTap: () => _sendTestNotification(ref),
                    ),
                  ),
                ),
              ],
            )
          else ...[
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
            child: YaruListTile(
              leading: const Icon(YaruIcons.send),
              title: const Text('Send Test Notification'),
              onTap: () => _sendTestNotification(ref),
            ),
          ),
          ],
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
                : useGrid
                    ? GridView.extent(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: sp,
                        mainAxisSpacing: sp,
                        children: [
                          for (final item in recent)
                            HistoryItemCard(item: item, iconCache: iconCache),
                        ],
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
