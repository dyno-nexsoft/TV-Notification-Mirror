part of 'tv_settings_screen.dart';

/// SUPPORT section — FAQs/Contact Support are stub (no backend yet); Version
/// is real, read from the installed package via `package_info_plus`.
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return const YaruSection(
      headline: Text('SUPPORT'),
      child: Column(
        children: [
          YaruListTile(
            leading: Icon(YaruIcons.information),
            title: Text('FAQs'),
            trailing: Icon(YaruIcons.pan_end),
            enabled: false,
          ),
          YaruListTile(
            leading: Icon(YaruIcons.chat_bubble),
            title: Text('Contact Support'),
            trailing: Icon(YaruIcons.pan_end),
            enabled: false,
          ),
          _VersionTile(),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data;
        return YaruListTile(
          leading: const Icon(YaruIcons.tag),
          title: const Text('Version'),
          trailing: Text(
            version != null
                ? '${version.version}+${version.buildNumber}'
                : '...',
          ),
        );
      },
    );
  }
}
