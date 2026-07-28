/// Network protocol constants shared between Phone client and TV server.
class MirrorProtocol {
  MirrorProtocol._();

  /// mDNS service type registration string.
  static const mdnsType = '_tvmirror._tcp';

  /// Default HTTP & WebSocket server port.
  static const defaultPort = 8080;

  /// REST API endpoint for initiating pairing (POST).
  static const apiPair = '/api/pair';

  /// REST API endpoint for confirming pairing PIN (POST).
  static const apiPairConfirm = '/api/pair/confirm';

  /// REST API endpoint for confirming pairing via a scanned QR token (POST).
  static const apiPairQr = '/api/pair/qr';

  /// WebSocket endpoint path.
  static const wsPath = '/ws';

  // ── WebSocket Event Names ──────────────────────────────────────────────────

  static const eventPing = 'ping';
  static const eventPong = 'pong';
  static const eventDisconnect = 'disconnect';
  static const eventSetDnd = 'set_dnd';
  static const eventToggleDnd = 'toggle_dnd';
  static const eventNotificationNew = 'notification_new';
  static const eventNotificationRemoved = 'notification_removed';

  // ── Overlay Positions ──────────────────────────────────────────────────────

  static const overlayTopRight = 'top_right';
  static const overlayTopLeft = 'top_left';
  static const overlayBottomRight = 'bottom_right';
  static const overlayBottomLeft = 'bottom_left';
}
