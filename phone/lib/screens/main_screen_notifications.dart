part of 'main_screen.dart';

/// Notification intake pipeline for [_MainScreenState]: applies blocking
/// rules, records history, and relays surviving notifications to the TV.
/// Split out from the main state class to keep `main_screen.dart` focused
/// on tab navigation and lifecycle wiring.
extension _NotificationHandling on _MainScreenState {
  /// Runs each incoming notification through the blocking rules (keywords,
  /// quiet hours, per-app filter) before recording it and relaying it to the TV.
  void _handleNewNotification(NotificationItem item) async {
    if (_isBlockedByKeyword(item)) return;
    if (_isBlockedByQuietHours(item)) return;

    // Dynamically register new apps
    if (!_appFilters.containsKey(item.packageName)) {
      await _saveFilter(item.packageName, true);
    }

    // Per-app filter
    if (!(_appFilters[item.packageName] ?? true)) {
      debugPrint("Notification from ${item.packageName} filtered out.");
      return;
    }

    if (mounted) {
      _refresh(() {
        _history.insert(0, item);
        if (_history.length > 50) _history.removeLast();
      });
    }

    await _ensureIconCached(item.packageName);
    await _relayToTv(item);
  }

  bool _isBlockedByKeyword(NotificationItem item) {
    final blockedKw = MirrorFilterEvaluator.findMatchingBlockedKeyword(
      item.title,
      item.text,
      _settings.blockedKeywords,
    );
    if (blockedKw != null) {
      debugPrint("Notification blocked by keyword '$blockedKw': ${item.title}");
      return true;
    }
    return false;
  }

  bool _isBlockedByQuietHours(NotificationItem item) {
    if (_settings.quietHoursEnabled &&
        MirrorFilterEvaluator.isTimeInQuietHours(
          _settings.quietHoursStart,
          _settings.quietHoursEnd,
          DateTime.now(),
        )) {
      debugPrint(
          "Notification blocked by Quiet Hours schedule: ${item.title}");
      return true;
    }
    return false;
  }

  Future<void> _ensureIconCached(String pkg) async {
    if (_appIconCache.containsKey(pkg)) return;
    try {
      final appInfo = await InstalledApps.getAppInfo(pkg);
      _appIconCache[pkg] = appInfo?.icon;
      if (mounted) _refresh(() {});
    } catch (_) {}
  }

  Future<void> _relayToTv(NotificationItem item) async {
    if (!_isConnected) {
      debugPrint(
          "Notification received while offline. Attempting fast reconnect...");
      await _connector.connectToSavedTv();
      if (mounted) _refresh(() => _isConnected = _connector.isConnected);
    }

    if (_isConnected) {
      final iconBytes = _appIconCache[item.packageName];
      final base64Icon = iconBytes != null ? base64Encode(iconBytes) : null;
      _connector.sendNotification(
        item,
        base64Icon: base64Icon,
        overlayPosition: _settings.overlayPosition,
        overlayDurationMs: _settings.overlayDurationSeconds * 1000,
      );
    } else {
      debugPrint("Failed to send notification to TV: Connection is offline.");
    }
  }

  void _sendTestNotification() {
    final testItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      packageName: 'com.dyno.tv_notification_mirror.phone',
      appName: 'TV Mirror',
      title: 'Jane Doe',
      text: 'Hello from your TV Mirror app! 📺✨',
      postTime: DateTime.now().millisecondsSinceEpoch,
    );
    _handleNewNotification(testItem);
  }
}
