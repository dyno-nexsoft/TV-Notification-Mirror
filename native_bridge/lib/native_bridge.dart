import 'native_bridge_platform_interface.dart';

class NativeBridge {
  Future<String?> getPlatformVersion() {
    return NativeBridgePlatform.instance.getPlatformVersion();
  }
}
