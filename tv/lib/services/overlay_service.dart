import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native Kotlin overlay window (SYSTEM_ALERT_WINDOW) and its
/// runtime permissions, since Flutter has no built-in overlay-window API.
class OverlayService {
  static const _channel =
      MethodChannel('com.dyno.tv_notification_mirror/overlay');

  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint("Failed to check overlay permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to request overlay permission: ${e.message}");
    }
  }

  static Future<bool> checkNotificationPermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkNotificationPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint("Failed to check notification permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      debugPrint("Failed to request notification permission: ${e.message}");
    }
  }

  static Future<void> showOverlay({
    required String title,
    required String text,
    required String appName,
    String? base64Icon,
    String? overlayPosition,
    int? overlayDurationMs,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'title': title,
        'text': text,
        'appName': appName,
        'base64Icon': base64Icon,
        'overlayPosition': overlayPosition,
        'duration': overlayDurationMs ?? 5000,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to show overlay: ${e.message}");
    }
  }

  static Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to hide overlay: ${e.message}");
    }
  }
}
