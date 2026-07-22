import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import '../../models/notification_item.dart';
import '../app_icon_widget.dart';

/// A single notification history item card using YaruTile.
class HistoryItemCard extends StatelessWidget {
  final NotificationItem item;
  final Map<String, Uint8List?> iconCache;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.iconCache,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final timeStr = DateTime.fromMillisecondsSinceEpoch(item.postTime)
        .toLocal()
        .toString()
        .substring(11, 16);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: YaruTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withValues(alpha: 0.15),
          radius: 20,
          child: AppIconWidget(
            packageName: item.packageName,
            fallbackIcon: YaruIcons.notification,
            fallbackColor: primaryColor,
            cache: iconCache,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            if (item.text.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
