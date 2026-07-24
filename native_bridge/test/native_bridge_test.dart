import 'package:flutter_test/flutter_test.dart';
import 'package:native_bridge/native_bridge.dart';
import 'package:native_bridge/native_bridge_platform_interface.dart';
import 'package:native_bridge/native_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeBridgePlatform
    with MockPlatformInterfaceMixin
    implements NativeBridgePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeBridgePlatform initialPlatform = NativeBridgePlatform.instance;

  test('$MethodChannelNativeBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeBridge>());
  });

  test('getPlatformVersion', () async {
    NativeBridge nativeBridgePlugin = NativeBridge();
    MockNativeBridgePlatform fakePlatform = MockNativeBridgePlatform();
    NativeBridgePlatform.instance = fakePlatform;

    expect(await nativeBridgePlugin.getPlatformVersion(), '42');
  });
}
