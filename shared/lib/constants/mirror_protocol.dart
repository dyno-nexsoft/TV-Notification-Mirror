/// Network protocol constants shared between Phone client and TV server.
class MirrorProtocol {
  MirrorProtocol._();

  /// mDNS service type registration string.
  static const String mdnsType = '_tvmirror._tcp';

  /// Default HTTP & WebSocket server port.
  static const int defaultPort = 8080;

  /// REST API endpoint for initiating pairing (POST).
  static const String apiPair = '/api/pair';

  /// REST API endpoint for confirming pairing PIN (POST).
  static const String apiPairConfirm = '/api/pair/confirm';

  /// WebSocket endpoint path.
  static const String wsPath = '/ws';

  // ── WebSocket Event Names ──────────────────────────────────────────────────

  static const String eventPing = 'ping';
  static const String eventPong = 'pong';
  static const String eventDisconnect = 'disconnect';
  static const String eventSetDnd = 'set_dnd';
  static const String eventToggleDnd = 'toggle_dnd';
  static const String eventNotificationNew = 'notification_new';
  static const String eventNotificationRemoved = 'notification_removed';

  // ── Overlay Positions ──────────────────────────────────────────────────────

  static const String overlayTopRight = 'top_right';
  static const String overlayTopLeft = 'top_left';
  static const String overlayBottomRight = 'bottom_right';
  static const String overlayBottomLeft = 'bottom_left';
}
