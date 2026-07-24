import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../providers/phone_providers.dart';

/// Card for configuring quiet hours (scheduled DND) using Yaru UI widgets.
/// Uses [YaruTimeEntry] for inline, segmented time input — no dialog picker needed.
class QuietHoursCard extends ConsumerWidget {
  const QuietHoursCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);

    return asyncSettings.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (settings) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: YaruSection(
          headline: const Text('Quiet Hours (DND Schedule)'),
          child: Column(
            children: [
              YaruListTile(
                leading: const Icon(YaruIcons.notification),
                title: const Text('Quiet Hours Status'),
                subtitle:
                    const Text('Silence TV notifications during set hours'),
                trailing: YaruSwitch(
                  value: settings.quietHoursEnabled,
                  onChanged: (val) {
                    final updated = settings.copyWith(quietHoursEnabled: val);
                    ref.read(settingsProvider.notifier).updateSettings(updated);
                  },
                ),
              ),
              if (settings.quietHoursEnabled) ...[
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // Start time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            const Text('Start'),
                            YaruTimeEntry(
                              initialTimeOfDay: settings.quietHoursStart,
                              force24HourFormat: true,
                              onChanged: (time) {
                                if (time == null) return;
                                final updated =
                                    settings.copyWith(quietHoursStart: time);
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(updated);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(YaruIcons.go_next),
                      ),
                      // End time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            const Text('End'),
                            YaruTimeEntry(
                              initialTimeOfDay: settings.quietHoursEnd,
                              force24HourFormat: true,
                              onChanged: (time) {
                                if (time == null) return;
                                final updated =
                                    settings.copyWith(quietHoursEnd: time);
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(updated);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
