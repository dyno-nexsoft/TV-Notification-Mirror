part of 'tv_home_screen.dart';

/// Do Not Disturb switch plus quick-duration presets. Tapping a preset chip
/// enables DND for that duration (auto-clearing once it elapses), regardless
/// of the switch's current state.
class _DoNotDisturbSection extends ConsumerWidget {
  const _DoNotDisturbSection({required this.isDnd});

  final bool isDnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvServiceStateProvider.notifier);

    return YaruSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          YaruSwitchListTile(
            title: const Text('Do Not Disturb'),
            subtitle: Text(isDnd ? 'On' : 'Off'),
            value: isDnd,
            onChanged: (_) => notifier.toggleDnd(),
          ),
          Wrap(
            spacing: 8,
            children: [
              _DndDurationChip(
                label: '1 Hour',
                onTap: () =>
                    notifier.setDndForDuration(const Duration(hours: 1)),
              ),
              _DndDurationChip(
                label: '6 Hours',
                onTap: () =>
                    notifier.setDndForDuration(const Duration(hours: 6)),
              ),
              _DndDurationChip(
                label: 'Until Tomorrow',
                onTap: () {
                  final now = DateTime.now();
                  final midnight = DateTime(now.year, now.month, now.day + 1);
                  notifier.setDndForDuration(midnight.difference(now));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DndDurationChip extends StatelessWidget {
  const _DndDurationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
