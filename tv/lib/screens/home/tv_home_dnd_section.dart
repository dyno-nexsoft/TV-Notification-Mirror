part of 'tv_home_screen.dart';

class _DoNotDisturbSection extends ConsumerWidget {
  const _DoNotDisturbSection({
    required this.isDnd,
    this.dndUntilEpochMs,
  });

  final bool isDnd;
  final int? dndUntilEpochMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvServiceStateProvider.notifier);
    final remaining = _computeRemaining();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return YaruSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          YaruSwitchListTile(
            title: const Text('Do Not Disturb'),
            subtitle: Text(_subtitle(remaining)),
            value: isDnd,
            onChanged: (_) => notifier.toggleDnd(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DndDurationChip(
                  label: '1 Hour',
                  isSelected: _isDurationActive(remaining, 60),
                  colorScheme: colorScheme,
                  onTap: () =>
                      notifier.setDndForDuration(const Duration(hours: 1)),
                ),
                _DndDurationChip(
                  label: '6 Hours',
                  isSelected: _isDurationActive(remaining, 360),
                  colorScheme: colorScheme,
                  onTap: () =>
                      notifier.setDndForDuration(const Duration(hours: 6)),
                ),
                _DndDurationChip(
                  label: 'Until Tomorrow',
                  isSelected: isDnd &&
                      remaining != null &&
                      remaining != Duration.zero &&
                      _isUntilTomorrow(remaining),
                  colorScheme: colorScheme,
                  onTap: () {
                    final now = DateTime.now();
                    final midnight =
                        DateTime(now.year, now.month, now.day + 1);
                    notifier.setDndForDuration(midnight.difference(now));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Duration? _computeRemaining() {
    if (dndUntilEpochMs == null) return null;
    final remaining = Duration(
      milliseconds:
          dndUntilEpochMs! - DateTime.now().millisecondsSinceEpoch,
    );
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _subtitle(Duration? remaining) {
    if (!isDnd) return 'Off';
    if (remaining == null) return 'On indefinitely';
    if (remaining == Duration.zero) return 'Ending\u2026';
    final parts = <String>[];
    if (remaining.inDays > 0) {
      parts.add('${remaining.inDays}d');
      parts.add('${remaining.inHours % 24}h');
    } else if (remaining.inHours > 0) {
      parts.add('${remaining.inHours}h');
      parts.add('${remaining.inMinutes % 60}m');
    } else {
      parts.add('${remaining.inMinutes}m');
      parts.add('${remaining.inSeconds % 60}s');
    }
    return 'On \u00b7 ${parts.join(' ')} remaining';
  }

  bool _isDurationActive(Duration? remaining, int expectedMinutes) {
    return isDnd &&
        remaining != null &&
        remaining != Duration.zero &&
        (remaining.inMinutes - expectedMinutes).abs() <= 5;
  }

  bool _isUntilTomorrow(Duration remaining) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final expected = midnight.difference(now);
    return (remaining.inMinutes - expected.inMinutes).abs() <= 5;
  }
}

class _DndDurationChip extends StatelessWidget {
  const _DndDurationChip({
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimaryContainer : null,
      ),
    );
  }
}
