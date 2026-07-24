// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    _NotificationItem(
      id: _readId(json, 'id') as String,
      packageName: json['packageName'] as String? ?? 'unknown',
      appName: json['appName'] as String? ?? 'Notification',
      title: json['title'] as String? ?? 'Notification',
      text: json['text'] as String? ?? '',
      postTime: (_readPostTime(json, 'postTime') as num).toInt(),
      appIcon: json['appIcon'] as String?,
      overlayPosition: json['overlayPosition'] as String?,
      overlayDuration: (json['overlayDuration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NotificationItemToJson(_NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'packageName': instance.packageName,
      'appName': instance.appName,
      'title': instance.title,
      'text': instance.text,
      'postTime': instance.postTime,
      'appIcon': instance.appIcon,
      'overlayPosition': instance.overlayPosition,
      'overlayDuration': instance.overlayDuration,
    };
