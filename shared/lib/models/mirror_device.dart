import 'dart:convert';

/// Represents a TV or Phone device in the TV Notification Mirror network.
class MirrorDevice {
  final String name;
  final String ip;
  final int port;
  final String? token;

  const MirrorDevice({
    required this.name,
    required this.ip,
    required this.port,
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceName': name,
      'ip': ip,
      'port': port,
      if (token != null) 'token': token,
    };
  }

  factory MirrorDevice.fromMap(Map<String, dynamic> map) {
    return MirrorDevice(
      name: map['deviceName'] as String? ?? map['name'] as String? ?? 'Unknown Device',
      ip: map['ip'] as String? ?? '',
      port: map['port'] as int? ?? 8080,
      token: map['token'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MirrorDevice.fromJson(String source) =>
      MirrorDevice.fromMap(jsonDecode(source));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MirrorDevice &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}
