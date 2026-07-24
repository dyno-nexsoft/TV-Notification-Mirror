import 'dart:typed_data';
import 'package:shared/shared.dart';

/// A single toggle row for one installed app in the App Filters list using Yaru UI.
class AppFilterTile extends StatelessWidget {
  const AppFilterTile({
    super.key,
    required this.packageName,
    required this.appName,
    required this.isEnabled,
    required this.iconCache,
    required this.onToggle,
  });
  final String packageName;
  final String appName;
  final bool isEnabled;
  final Map<String, Uint8List?> iconCache;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: YaruListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppIconWidget(
            packageName: packageName,
            fallbackIcon: YaruIcons.notification,
            fallbackColor: primaryColor,
            cache: iconCache,
          ),
        ),
        title: Text(appName),
        subtitle: Text(packageName),
        trailing: YaruSwitch(
          value: isEnabled,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
