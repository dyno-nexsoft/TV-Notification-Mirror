import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/notification_item.dart';

class NotificationService {
  static const _methodsChannel =
      MethodChannel('com.dyno.tv_notification_mirror/methods');
  static const _eventsChannel =
      EventChannel('com.dyno.tv_notification_mirror/events');

  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  NotificationService() {
    _eventsChannel.receiveBroadcastStream().listen(
      (data) {
        if (data is Map) {
          _controller.add(Map<String, dynamic>.from(data));
        }
      },
      onError: (err) {
        debugPrint("EventChannel error: $err");
      },
    );
  }

  Stream<Map<String, dynamic>> get rawStream => _controller.stream;

  Stream<NotificationItem> get notificationStream => _controller.stream
      .where((event) => event['event'] == 'notification_new')
      .map((event) => NotificationItem.fromMap(event));

  Stream<String> get notificationRemovedStream => _controller.stream
      .where((event) => event['event'] == 'notification_removed')
      .map((event) => event['id'] as String);

  Future<bool> checkPermission() async {
    try {
      final bool hasPermission =
          await _methodsChannel.invokeMethod('checkPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: ${e.message}");
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _methodsChannel.invokeMethod('openSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: ${e.message}");
    }
  }
}
