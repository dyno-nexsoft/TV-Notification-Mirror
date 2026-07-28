part of 'tv_settings_screen.dart';

/// SUPPORT section — FAQs and Contact Support open GitHub URLs; Version is
/// real, read from the installed package via `package_info_plus`.
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: const Text('SUPPORT'),
      child: Column(
        children: [
          YaruListTile(
            leading: const Icon(YaruIcons.information),
            title: const Text('FAQs'),
            trailing: const Icon(YaruIcons.pan_end),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/dyno-nexsoft/TV-Notification-Mirror'
                '/blob/main/doc/faq.md',
              ),
            ),
          ),
          YaruListTile(
            leading: const Icon(YaruIcons.chat_bubble),
            title: const Text('Contact Support'),
            trailing: const Icon(YaruIcons.pan_end),
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/dyno-nexsoft/TV-Notification-Mirror'
                '/issues',
              ),
            ),
          ),
          const _VersionTile(),
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
