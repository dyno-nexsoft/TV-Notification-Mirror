import 'package:flutter/services.dart';

/// Native helpers for the battery-optimization whitelist. Stock Android (Doze)
/// and OEM ROMs (MIUI, ColorOS, EMUI, ...) can stop the background service
/// unless the user exempts the app — see `doc/architecture.md`.
class BatteryOptimizationService {
  BatteryOptimizationService._();

  static const _channel = MethodChannel(
    'com.dyno.tv_notification_mirror/methods',
  );

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool ignoring = await _channel
          .invokeMethod('isIgnoringBatteryOptimizations');
      return ignoring;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system "ignore battery optimizations" dialog for this app so
  /// the user can whitelist it. Falls back to the app list on failure. Returns
  /// whether any settings screen actually opened — `false` (e.g. Fire TV) means
  /// the caller should show the ADB whitelist guide.
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      return await _channel
          .invokeMethod<bool>('requestIgnoreBatteryOptimizations') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the generic battery-optimization app list. Returns whether the
  /// screen could be opened (some devices, e.g. Fire TV, have none).
  static Future<bool> openBatteryOptimizationSettings() async {
    try {
      return await _channel
          .invokeMethod<bool>('openBatteryOptimizationSettings') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
