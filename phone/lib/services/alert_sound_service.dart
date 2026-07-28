import 'package:flutter/services.dart';

/// Bridges the phone's own alert-sound picker/player — mirrors the TV app's
/// `OverlayService` RingtoneManager bridge, but scoped to what plays locally
/// on the phone when using "Send Test Notification".
class AlertSoundService {
  AlertSoundService._();

  static const _channel = MethodChannel(
    'com.dyno.tv_notification_mirror.phone/alertsound',
  );

  static Future<String?> pickAlertSound() async {
    try {
      return await _channel.invokeMethod<String>('pickAlertSound');
    } catch (_) {
      return null;
    }
  }

  static Future<void> playAlertSound(String? uri) async {
    try {
      await _channel.invokeMethod('playAlertSound', {'uri': uri});
    } catch (_) {}
  }
}
