/// Severity of a debug log entry.
enum DebugLogLevel { debug, info, warn, error }

/// A single entry in the in-memory debug log ring buffer. Entries are
/// produced in the background isolate, shipped to the UI isolate through
/// `service.invoke('debugLog', ...)`, and rendered by `DebugLogScreen`.
class DebugLogEntry {
  const DebugLogEntry({
    required this.time,
    required this.level,
    required this.source,
    required this.message,
  });

  factory DebugLogEntry.fromMap(Map<String, dynamic> map) {
    return DebugLogEntry(
      time: DateTime.fromMillisecondsSinceEpoch(map['time'] as int? ?? 0),
      level: DebugLogLevel.values.asNameMap()[map['level']] ??
          DebugLogLevel.debug,
      source: map['source'] as String? ?? '',
      message: map['message'] as String? ?? '',
    );
  }

  final DateTime time;
  final DebugLogLevel level;
  final String source;
  final String message;

  Map<String, dynamic> toMap() {
    return {
      'time': time.millisecondsSinceEpoch,
      'level': level.name,
      'source': source,
      'message': message,
    };
  }
}
