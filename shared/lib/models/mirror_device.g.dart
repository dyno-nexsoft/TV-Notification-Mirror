// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mirror_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MirrorDevice _$MirrorDeviceFromJson(Map<String, dynamic> json) =>
    _MirrorDevice(
      name: _readDeviceName(json, 'deviceName') as String,
      ip: json['ip'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 8080,
      token: json['token'] as String?,
    );

Map<String, dynamic> _$MirrorDeviceToJson(_MirrorDevice instance) =>
    <String, dynamic>{
      'deviceName': instance.name,
      'ip': instance.ip,
      'port': instance.port,
      'token': instance.token,
    };
