import 'package:freezed_annotation/freezed_annotation.dart';

part 'mirror_device.freezed.dart';
part 'mirror_device.g.dart';

Object? _readDeviceName(Map map, String key) {
  return map['deviceName'] ?? map['name'] ?? 'Unknown Device';
}

/// Represents a TV or Phone device in the TV Notification Mirror network.
@freezed
abstract class MirrorDevice with _$MirrorDevice {
  const factory MirrorDevice({
    @JsonKey(name: 'deviceName', readValue: _readDeviceName)
    required String name,
    @Default('') String ip,
    @Default(8080) int port,
    String? token,
  }) = _MirrorDevice;

  factory MirrorDevice.fromJson(Map<String, dynamic> json) =>
      _$MirrorDeviceFromJson(json);
}
