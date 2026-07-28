import 'package:shared/shared.dart';

/// A TV-optimised paired device card using Yaru UI widgets: online status,
/// last-synced time, and Rename/Remove actions.
class PairedDeviceCard extends StatelessWidget {
  const PairedDeviceCard({
    super.key,
    required this.deviceName,
    required this.isOnline,
    required this.lastSyncedAt,
    required this.onRename,
    required this.onRemove,
  });

  final String deviceName;
  final bool isOnline;
  final int? lastSyncedAt;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  String get _lastSyncedLabel {
    if (lastSyncedAt == null) return 'Never synced';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastSyncedAt!),
    );
    if (diff.inMinutes < 1) return 'Last synced: Just now';
    if (diff.inMinutes < 60) {
      return 'Last synced: ${diff.inMinutes} minutes ago';
    }
    if (diff.inHours < 24) return 'Last synced: ${diff.inHours} hours ago';
    return 'Last synced: ${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return YaruSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(YaruIcons.phone),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            deviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusDot(isOnline: isOnline),
                        Text(isOnline ? 'Connected' : 'Offline'),
                      ],
                    ),
                    Text(_lastSyncedLabel),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: onRename, child: const Text('Rename')),
              OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(YaruIcons.trash),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
