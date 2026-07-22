import 'dart:convert';

/// Represents a single notification payload shared between Phone and TV apps.
class NotificationItem {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final int postTime;
  final String? appIcon;
  final String? overlayPosition;
  final int? overlayDuration;

  NotificationItem({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postTime,
    this.appIcon,
    this.overlayPosition,
    this.overlayDuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'text': text,
      'postTime': postTime,
      if (appIcon != null) 'appIcon': appIcon,
      if (overlayPosition != null) 'overlayPosition': overlayPosition,
      if (overlayDuration != null) 'overlayDuration': overlayDuration,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: map['packageName'] as String? ?? 'unknown',
      appName: map['appName'] as String? ?? getAppName(map['packageName'] as String? ?? ''),
      title: map['title'] as String? ?? 'Notification',
      text: map['text'] as String? ?? '',
      postTime: map['postTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      appIcon: map['appIcon'] as String?,
      overlayPosition: map['overlayPosition'] as String?,
      overlayDuration: map['overlayDuration'] as int?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NotificationItem.fromJson(String source) =>
      NotificationItem.fromMap(jsonDecode(source));

  static String getAppName(String packageName) {
    if (packageName.isEmpty) return 'Notification';

    final parts = packageName.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return packageName;
  }
}
