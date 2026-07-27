part of 'tv_settings_screen.dart';

/// ACCOUNT & DEVICE section — stub only: this app is P2P-local with no
/// backend account/cloud sync system yet. Layout matches the mockup but
/// every control is disabled (`onTap`/`onChanged` left null).
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return const YaruSection(
      headline: Text('ACCOUNT & DEVICE'),
      child: Column(
        children: [
          YaruListTile(
            leading: Icon(YaruIcons.user),
            title: Text('admin@notifytv.com'),
            subtitle: Text('Premium Plan'),
            enabled: false,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: null, child: Text('Sign Out')),
                FilledButton(
                  onPressed: null,
                  child: Text('Manage Account'),
                ),
              ],
            ),
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
