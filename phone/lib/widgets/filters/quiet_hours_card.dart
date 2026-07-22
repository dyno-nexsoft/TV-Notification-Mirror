import 'package:shared/shared.dart';
import '../../services/filter_service.dart';

/// Card for configuring quiet hours (scheduled DND) using Yaru UI widgets.
/// Uses [YaruTimeEntry] for inline, segmented time input — no dialog picker needed.
class QuietHoursCard extends StatelessWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  const QuietHoursCard({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  void _saveTime({
    required bool enabled,
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    FilterService.saveQuietHours(enabled: enabled, start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: YaruSection(
        headline: const Text('Quiet Hours (DND Schedule)'),
        child: Column(
          children: [
            YaruListTile(
              leading: const Icon(YaruIcons.notification, color: Colors.greenAccent),
              title: const Text(
                'Quiet Hours Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Silence TV notifications during set hours'),
              trailing: YaruSwitch(
                value: settings.quietHoursEnabled,
                onChanged: (val) {
                  final updated = settings.copyWith(quietHoursEnabled: val);
                  onChanged(updated);
                  _saveTime(
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    // Start time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          YaruTimeEntry(
                            initialTimeOfDay: settings.quietHoursStart,
                            force24HourFormat: true,
                            onChanged: (time) {
                              if (time == null) return;
                              final updated = settings.copyWith(quietHoursStart: time);
                              onChanged(updated);
                              _saveTime(
                                enabled: updated.quietHoursEnabled,
                                start: updated.quietHoursStart,
                                end: updated.quietHoursEnd,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(YaruIcons.go_next, color: Colors.grey),
                    ),
                    // End time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'End',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          YaruTimeEntry(
                            initialTimeOfDay: settings.quietHoursEnd,
                            force24HourFormat: true,
                            onChanged: (time) {
                              if (time == null) return;
                              final updated = settings.copyWith(quietHoursEnd: time);
                              onChanged(updated);
                              _saveTime(
                                enabled: updated.quietHoursEnabled,
                                start: updated.quietHoursStart,
                                end: updated.quietHoursEnd,
                              );
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
    );
  }
}
