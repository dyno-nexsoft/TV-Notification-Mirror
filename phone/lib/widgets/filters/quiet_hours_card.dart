import 'package:shared/shared.dart';
import '../../services/filter_service.dart';

/// Card for configuring quiet hours (scheduled DND) using Yaru UI widgets.
class QuietHoursCard extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const QuietHoursCard({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = settings.quietHoursStart.format(context);
    final endStr = settings.quietHoursEnd.format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: YaruSection(
        headline: const Text('Quiet Hours (DND Schedule)'),
        child: Column(
          children: [
            YaruListTile(
              leading: Icon(YaruIcons.notification, color: Colors.greenAccent),
              title: const Text(
                'Quiet Hours Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Silence TV notifications during set hours'),
              trailing: YaruSwitch(
                value: settings.quietHoursEnabled,
                onChanged: (val) {
                  onChanged(settings.copyWith(quietHoursEnabled: val));
                  FilterService.saveQuietHours(
                    enabled: val,
                    start: settings.quietHoursStart,
                    end: settings.quietHoursEnd,
                  );
                },
              ),
            ),
            if (settings.quietHoursEnabled) ...[
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    YaruOptionButton(
                      onPressed: () async {
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: settings.quietHoursStart,
                        );
                        if (selected != null) {
                          final updated = settings.copyWith(
                            quietHoursStart: selected,
                          );
                          onChanged(updated);
                          FilterService.saveQuietHours(
                            enabled: updated.quietHoursEnabled,
                            start: updated.quietHoursStart,
                            end: updated.quietHoursEnd,
                          );
                        }
                      },
                      child: Text('Start: $startStr'),
                    ),
                    Icon(YaruIcons.go_next, color: Colors.grey),
                    YaruOptionButton(
                      onPressed: () async {
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: settings.quietHoursEnd,
                        );
                        if (selected != null) {
                          final updated = settings.copyWith(
                            quietHoursEnd: selected,
                          );
                          onChanged(updated);
                          FilterService.saveQuietHours(
                            enabled: updated.quietHoursEnabled,
                            start: updated.quietHoursStart,
                            end: updated.quietHoursEnd,
                          );
                        }
                      },
                      child: Text('End: $endStr'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
