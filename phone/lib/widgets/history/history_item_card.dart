import 'dart:typed_data';
import 'package:shared/shared.dart';

/// A single notification history item card using YaruTile.
class HistoryItemCard extends StatelessWidget {
  const HistoryItemCard({
    super.key,
    required this.item,
    required this.iconCache,
  });
  final NotificationItem item;
  final Map<String, Uint8List?> iconCache;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final timeStr = DateTime.fromMillisecondsSinceEpoch(item.postTime)
        .toLocal()
        .toString()
        .substring(11, 16);

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
            packageName: item.packageName,
            fallbackIcon: YaruIcons.notification,
            fallbackColor: primaryColor,
            cache: iconCache,
            size: 22,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.appName,
            ),
            Text(
              timeStr,
            ),
          ],
        ),
        subtitle: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
            ),
            if (item.text.isNotEmpty)
              Text(
                item.text,
              ),
          ],
        ),
      ),
    );
  }
}
