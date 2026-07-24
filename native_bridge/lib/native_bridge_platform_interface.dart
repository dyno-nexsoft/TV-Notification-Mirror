import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_bridge_method_channel.dart';

abstract class NativeBridgePlatform extends PlatformInterface {
  /// Constructs a NativeBridgePlatform.
  NativeBridgePlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeBridgePlatform _instance = MethodChannelNativeBridge();

  /// The default instance of [NativeBridgePlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeBridge].
  static NativeBridgePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeBridgePlatform] when
  /// they register themselves.
  static set instance(NativeBridgePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
