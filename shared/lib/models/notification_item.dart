import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_item.freezed.dart';
part 'notification_item.g.dart';

Object? _readId(Map map, String key) {
  return map['id']?.toString() ??
      DateTime.now().millisecondsSinceEpoch.toString();
}

Object? _readPostTime(Map map, String key) {
  return map['postTime'] ??
      map['timestamp'] ??
      DateTime.now().millisecondsSinceEpoch;
}

/// Represents a single notification payload shared between Phone and TV apps.
@freezed
abstract class NotificationItem with _$NotificationItem {
  const factory NotificationItem({
    @JsonKey(readValue: _readId) required String id,
    @Default('unknown') String packageName,
    @Default('Notification') String appName,
    @Default('Notification') String title,
    @Default('') String text,
    @JsonKey(readValue: _readPostTime) required int postTime,
    String? appIcon,
    String? overlayPosition,
    int? overlayDuration,
  }) = _NotificationItem;

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemFromJson(json);

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
