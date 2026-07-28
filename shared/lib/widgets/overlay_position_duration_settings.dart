import '../shared.dart';

/// The overlay's popup-position picker + display-duration stepper, shared
/// verbatim between the TV and Phone apps' settings screens — both apps
/// store their own copy of these values locally and pass the TV's own
/// overlay-relevant values in with the notification, so each app just wires
/// value/onChanged to its own settings provider.
class OverlayPositionDurationSettings extends StatelessWidget {
  const OverlayPositionDurationSettings({
    super.key,
    required this.position,
    required this.onPositionChanged,
    required this.durationSeconds,
    required this.onDurationChanged,
    this.durationMin = 3,
    this.durationMax = 15,
  });

  final String position;
  final ValueChanged<String> onPositionChanged;
  final int durationSeconds;
  final ValueChanged<int> onDurationChanged;
  final double durationMin;
  final double durationMax;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text('Popup Position'),
        AnchorPositionPicker(value: position, onChanged: onPositionChanged),
        const SizedBox(height: 8),
        Text('Display Duration: $durationSeconds seconds'),
        ValueStepper(
          label: '$durationSeconds seconds',
          value: durationSeconds.toDouble(),
          min: durationMin,
          max: durationMax,
          step: 1,
          onChanged: (v) => onDurationChanged(v.round()),
        ),
      ],
    );
  }
}
