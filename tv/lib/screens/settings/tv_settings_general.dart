part of 'tv_settings_screen.dart';

/// GENERAL section: Language (stub — no backend account/locale system yet)
/// and Launch on Boot (real, gates `BootReceiver` on the native side).
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection({required this.settings});

  final TvSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YaruSection(
      headline: const Text('GENERAL'),
      child: Column(
        children: [
          const YaruListTile(
            title: Text('Language'),
            subtitle: Text('Select your preferred interface language'),
            trailing: Text('English (US)'),
          ),
          YaruSwitchListTile(
            title: const Text('Launch on Boot'),
            subtitle: const Text(
              'Automatically start the app when TV turns on',
            ),
            value: settings.launchOnBoot,
            onChanged: (value) =>
                ref.read(tvSettingsProvider.notifier).setLaunchOnBoot(value),
          ),
          YaruSwitchListTile(
            title: const Text('Debug Status Overlay'),
            subtitle: const Text(
              'Show a persistent on-screen HUD: server state, connected clients, DND',
            ),
            value: settings.statusOverlayEnabled,
            onChanged: (value) =>
                ref.read(tvSettingsProvider.notifier).setStatusOverlayEnabled(value),
          ),
        ],
      ),
    );
  }
}
