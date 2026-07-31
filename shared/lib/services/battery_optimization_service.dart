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
  /// the user can whitelist it. Falls back to the app list on failure.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
    } on PlatformException {
      // Best-effort; ignore failures.
    }
  }

  /// Opens the generic battery-optimization app list.
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException {
      // Best-effort; ignore failures.
    }
  }
}
