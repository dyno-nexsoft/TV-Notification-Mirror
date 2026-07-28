import '../shared.dart';

/// The "TV Overlay Settings" card — wraps the shared popup-position/
/// display-duration controls. Used identically by the TV and Phone apps'
/// settings screens.
class TvOverlaySettingsCard extends StatelessWidget {
  const TvOverlaySettingsCard({
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
    return YaruSection(
      headline: const Row(
        spacing: 8,
        children: [
          Icon(YaruIcons.computer),
          Text('TV Overlay Settings'),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OverlayPositionDurationSettings(
          position: position,
          onPositionChanged: onPositionChanged,
          durationSeconds: durationSeconds,
          onDurationChanged: onDurationChanged,
          durationMin: durationMin,
          durationMax: durationMax,
        ),
      ),
    );
  }
}
