part of 'tv_settings_screen.dart';

/// DISPLAY section: theme mode and overlay opacity, both real and applied
/// immediately (theme via [MyApp], opacity via the native overlay drawable).
class _DisplaySection extends ConsumerWidget {
  const _DisplaySection({required this.settings});

  final TvSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tvSettingsProvider.notifier);

    return YaruSection(
      headline: const Text('DISPLAY'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Text('Appearance'),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      notifier.setThemeMode(selection.first),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overlay Opacity'),
                ValueStepper(
                  label: '${(settings.overlayOpacity * 100).round()}%',
                  value: settings.overlayOpacity,
                  min: 0.5,
                  max: 1.0,
                  step: 0.05,
                  onChanged: notifier.setOverlayOpacity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
