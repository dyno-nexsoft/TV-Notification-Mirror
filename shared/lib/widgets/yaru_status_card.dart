import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

/// Shared status badge / card component using Yaru UI elements.
class YaruStatusCard extends StatelessWidget {
  final bool isConnected;
  final String title;
  final String? subtitle;
  final Widget? action;

  const YaruStatusCard({
    super.key,
    required this.isConnected,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return YaruSection(
      headline: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: YaruTile(
        leading: Icon(
          isConnected ? YaruIcons.ok_simple : YaruIcons.error,
          color: isConnected ? Colors.greenAccent : Colors.redAccent,
          size: 32,
        ),
        title: Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: action,
      ),
    );
  }
}
