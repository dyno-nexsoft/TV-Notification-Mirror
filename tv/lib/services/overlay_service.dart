import 'package:flutter/services.dart';

class OverlayService {
  static const _channel = MethodChannel('com.dyno.tv_notification_mirror/overlay');

  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check overlay permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (e) {
      print("Failed to request overlay permission: ${e.message}");
    }
  }

  static Future<bool> checkNotificationPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkNotificationPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print("Failed to check notification permission: ${e.message}");
      return false;
    }
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      print("Failed to request notification permission: ${e.message}");
    }
  }

  static Future<void> showOverlay({
    required String title,
    required String text,
    required String appName,
    int durationMs = 5000,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'title': title,
        'text': text,
        'appName': appName,
        'duration': durationMs,
      });
    } on PlatformException catch (e) {
      print("Failed to show overlay: ${e.message}");
    }
  }

  static Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      print("Failed to hide overlay: ${e.message}");
    }
  }
}
