import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../models/debug_log_entry.dart';
import 'debug_log_screen.dart';

/// Settings entry that opens the [DebugLogScreen] on a pushed route, with the
/// logs supplied by the caller's provider (Phone or TV debug log provider).
class DebugLogListTile extends StatelessWidget {
  const DebugLogListTile({
    super.key,
    required this.logs,
    required this.onClear,
    this.subtitle,
  });

  final List<DebugLogEntry> logs;
  final VoidCallback onClear;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return YaruListTile(
      leading: const Icon(YaruIcons.menu),
      title: const Text('Debug Log'),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(YaruIcons.pan_end),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DebugLogScreen(logs: logs, onClear: onClear),
        ),
      ),
    );
  }
}
