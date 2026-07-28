import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared.dart';

/// SUPPORT section — FAQs and Contact Support open the project's GitHub
/// docs/issues; Version is real, read from the installed package. Shared
/// between the TV and Phone apps since both point at the same repo. The app
/// display name is defined in [MirrorProtocol.appName].
class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  static const _faqUrl =
      'https://github.com/dyno-nexsoft/TV-Notification-Mirror'
      '/blob/main/doc/faq.md';
  static const _issuesUrl =
      'https://github.com/dyno-nexsoft/TV-Notification-Mirror/issues';

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
            onTap: () => launchUrl(Uri.parse(_faqUrl)),
          ),
          YaruListTile(
            leading: const Icon(YaruIcons.chat_bubble),
            title: const Text('Contact Support'),
            trailing: const Icon(YaruIcons.pan_end),
            onTap: () => launchUrl(Uri.parse(_issuesUrl)),
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
