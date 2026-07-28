import '../shared.dart';

/// A -/value/+ stepper used instead of [Slider] for settings that need to be
/// adjustable by a D-pad remote: Material's [Slider] registers `Shortcuts`
/// for all 4 arrow keys once focused (up/down/left/right all adjust its
/// value), so there is no directional key left to move focus away from it —
/// a real focus trap on TV. Two independently-focusable buttons don't have
/// that problem. Used on both apps for a consistent look on overlay settings
/// they share.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(YaruIcons.minus),
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
        ),
        Expanded(child: Text(label, textAlign: TextAlign.center)),
        IconButton(
          icon: const Icon(YaruIcons.plus),
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
        ),
      ],
    );
  }
}
