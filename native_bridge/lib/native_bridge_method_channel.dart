import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_bridge_platform_interface.dart';

/// An implementation of [NativeBridgePlatform] that uses method channels.
class MethodChannelNativeBridge extends NativeBridgePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_bridge');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
