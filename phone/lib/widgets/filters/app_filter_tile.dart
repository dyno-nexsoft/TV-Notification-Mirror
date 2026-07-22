import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import '../app_icon_widget.dart';

/// A single toggle row for one installed app in the App Filters list using Yaru UI.
class AppFilterTile extends StatelessWidget {
  final String packageName;
  final String appName;
  final bool isEnabled;
  final Map<String, Uint8List?> iconCache;
  final ValueChanged<bool> onToggle;

  const AppFilterTile({
    super.key,
    required this.packageName,
    required this.appName,
    required this.isEnabled,
    required this.iconCache,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: YaruListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.15),
          child: AppIconWidget(
            packageName: packageName,
            fallbackIcon: YaruIcons.notification,
            fallbackColor: primaryColor,
            cache: iconCache,
            size: 24,
          ),
        ),
        title: Text(
          appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          packageName,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: YaruSwitch(
          value: isEnabled,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
