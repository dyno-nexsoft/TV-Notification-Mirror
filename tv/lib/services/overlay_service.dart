import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native Kotlin overlay window (SYSTEM_ALERT_WINDOW) and its
/// runtime permissions, since Flutter has no built-in overlay-window API.
class OverlayService {
  static const _channel = MethodChannel(
    'com.dyno.tv_notification_mirror/overlay',
  );

  /// Native broadcast bridge, handled by the `native_bridge` plugin which is
  /// registered on BOTH the UI engine and the background service engine — so it
  /// works even when the UI Activity/isolate has been destroyed.
  static const _methodsChannel = MethodChannel(
    'com.dyno.tv_notification_mirror/methods',
  );

  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
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
      final bool hasPermission = await _channel.invokeMethod(
        'checkNotificationPermission',
      );
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
    String category = 'generic',
    double overlayOpacity = 0.95,
    String? alertSoundUri,
  }) async {
    try {
      await _channel.invokeMethod('showOverlay', {
        'title': title,
        'text': text,
        'appName': appName,
        'base64Icon': base64Icon,
        'overlayPosition': overlayPosition,
        'duration': overlayDurationMs ?? 5000,
        'category': category,
        'overlayOpacity': overlayOpacity,
        'alertSoundUri': alertSoundUri,
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

  /// Shows the overlay from the background isolate by broadcasting to the
  /// application-scoped native receiver. Unlike [showOverlay] this does not
  /// depend on the UI Activity/Flutter UI isolate being alive, so it keeps
  /// working after the TV app is killed from the recents screen.
  static Future<void> broadcastShowOverlay({
    required String title,
    required String text,
    required String appName,
    String? base64Icon,
    String? overlayPosition,
    int? overlayDurationMs,
    String category = 'generic',
    double overlayOpacity = 0.95,
    String? alertSoundUri,
  }) async {
    try {
      await _methodsChannel.invokeMethod('broadcastShowOverlay', {
        'title': title,
        'text': text,
        'appName': appName,
        'base64Icon': base64Icon,
        'overlayPosition': overlayPosition,
        'duration': overlayDurationMs ?? 5000,
        'category': category,
        'overlayOpacity': overlayOpacity,
        'alertSoundUri': alertSoundUri,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to broadcast show overlay: ${e.message}");
    }
  }

  /// Hides the overlay from the background isolate (see [broadcastShowOverlay]).
  static Future<void> broadcastHideOverlay() async {
    try {
      await _methodsChannel.invokeMethod('broadcastHideOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to broadcast hide overlay: ${e.message}");
    }
  }

  /// Shows the persistent debug status HUD (server state, connected clients,
  /// DND). Broadcast-based so it works even after the UI isolate is gone.
  static Future<void> broadcastShowStatusOverlay() async {
    try {
      await _methodsChannel.invokeMethod('broadcastShowStatusOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to broadcast show status overlay: ${e.message}");
    }
  }

  /// Hides the debug status HUD (see [broadcastShowStatusOverlay]).
  static Future<void> broadcastHideStatusOverlay() async {
    try {
      await _methodsChannel.invokeMethod('broadcastHideStatusOverlay');
    } on PlatformException catch (e) {
      debugPrint("Failed to broadcast hide status overlay: ${e.message}");
    }
  }

  /// Refreshes the debug status HUD text (see [broadcastShowStatusOverlay]).
  static Future<void> broadcastUpdateStatusOverlay(String text) async {
    try {
      await _methodsChannel.invokeMethod(
        'broadcastUpdateStatusOverlay',
        {'text': text},
      );
    } on PlatformException catch (e) {
      debugPrint("Failed to broadcast update status overlay: ${e.message}");
    }
  }

  /// Opens the native `RingtoneManager` picker (includes a "Silent" option)
  /// and returns the picked sound's URI string, `'silent'`, or `null` if the
  /// user cancelled.
  static Future<String?> pickAlertSound() async {
    try {
      return await _channel.invokeMethod<String>('pickAlertSound');
    } catch (e) {
      debugPrint("Failed to pick alert sound: $e");
      return null;
    }
  }
}
