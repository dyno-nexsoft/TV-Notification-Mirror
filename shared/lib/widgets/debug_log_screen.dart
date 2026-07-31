import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

import '../models/debug_log_entry.dart';

/// Full-screen debug log viewer. Displays a rolling list of [DebugLogEntry]s
/// with copyable message text so diagnostics can be pasted into bug reports.
class DebugLogScreen extends StatelessWidget {
  const DebugLogScreen({
    super.key,
    required this.logs,
    required this.onClear,
  });

  final List<DebugLogEntry> logs;
  final VoidCallback onClear;

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Log'),
        actions: [
          IconButton(
            icon: const Icon(YaruIcons.edit_clear),
            tooltip: 'Clear log',
            onPressed: logs.isEmpty ? null : onClear,
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No log entries yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final entry = logs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      '${_formatTime(entry.time)} '
                      '[${entry.level.name.toUpperCase()}] ${entry.source}',
                    ),
                    SelectableText(entry.message),
                  ],
                );
              },
            ),
    );
  }
}
