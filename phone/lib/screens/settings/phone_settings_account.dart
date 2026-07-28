part of 'phone_settings_screen.dart';

/// ACCOUNT section — stub only: this app is P2P-local with no backend
/// account/cloud sync system yet. Layout matches the mockup but every
/// control is disabled (`onTap`/`onChanged` left null).
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return const YaruSection(
      headline: Text('ACCOUNT'),
      child: Column(
        children: [
          YaruListTile(
            leading: Icon(YaruIcons.user),
            title: Text('admin@notifymirror.com'),
            subtitle: Text('Premium Plan'),
            enabled: false,
          ),
          YaruSwitchListTile(
            title: Text('Cloud Sync'),
            value: false,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
