import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared/shared.dart';

part 'debug_log_provider.g.dart';

/// Rolling in-memory buffer of debug log entries forwarded from the phone's
/// background isolate via `service.invoke('debugLog', ...)`. Kept alive so
/// the log survives tab switches while the app is running.
@Riverpod(keepAlive: true)
class DebugLog extends _$DebugLog {
  StreamSubscription? _sub;
  static const _maxEntries = 300;

  @override
  List<DebugLogEntry> build() {
    _sub?.cancel();
    _sub = FlutterBackgroundService().on('debugLog').listen((event) {
      if (event == null) return;
      final entry = DebugLogEntry.fromMap(Map<String, dynamic>.from(event));
      final entries = [...state, entry];
      state = entries.length > _maxEntries
          ? entries.sublist(entries.length - _maxEntries)
          : entries;
    });
    ref.onDispose(() => _sub?.cancel());
    return [];
  }

  void clear() => state = [];
}
