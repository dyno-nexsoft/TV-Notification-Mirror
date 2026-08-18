import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bonsoir/bonsoir.dart';
import 'package:shared/shared.dart' hide Router;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'tv_settings_service.dart';

/// A phone paired with (and optionally currently connected to) this TV.
typedef ConnectedClient = MirrorDevice;

/// Tracks an in-progress PIN-pairing session keyed by the phone's IP address,
/// so simultaneous pairing attempts from different phones don't race.
class _PairingSession {
  _PairingSession({required this.pin, required this.deviceName});
  final String pin;
  final String deviceName;
}

/// Owns the TV's half of the mirror link: the HTTP pairing API, mDNS
/// broadcast, and the WebSocket server that receives and forwards
/// notifications from paired phones. Singleton so the background isolate
/// and UI isolate observe the same server state.
class ServerService {
  factory ServerService() => _instance;
  ServerService._internal();
  static final _instance = ServerService._internal();

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;

  /// The port actually bound, which may differ from the requested one if that
  /// was taken. Advertised via mDNS and encoded in the pairing QR code.
  int? get serverPort => _server?.port;

  final _pairingSessions = <String, _PairingSession>{};

  /// Single-use token proactively displayed as a QR code on the Pair Device
  /// screen — unlike [_currentPin], this exists from server start (no need
  /// for the phone to call [_handlePairRequest] first) so it's scannable
  /// immediately. Regenerated after every successful use.
  String _qrToken = const Uuid().v4();
  String get currentQrToken => _qrToken;
  void regenerateQrToken() {
    _qrToken = const Uuid().v4();
    _log("QR pairing token regenerated.");
  }

  final List<ConnectedClient> _pairedClients = [];
  final Set<WebSocketChannel> _activeSockets = {};
  final Set<String> _activeTokens = {};
  final Map<WebSocketChannel, String> _socketToToken = {};

  final _pairingStateController = StreamController<String?>.broadcast();
  final _clientsController =
      StreamController<List<ConnectedClient>>.broadcast();
  final _overlayController = StreamController<Map<String, dynamic>>.broadcast();
  final _logController = StreamController<String>.broadcast();

  /// Logs [message] to console and forwards it to the background isolate's
  /// debug-log stream so the in-app Debug Log screen can surface it.
  void _log(String message) {
    debugPrint(message);
    if (!_logController.isClosed) _logController.add(message);
  }

  var _isRunning = false;
  var isDndEnabled = false;
  int? _dndUntilEpochMs;
  int? get dndUntilEpochMs => _dndUntilEpochMs;
  var _settings = const TvSettings();
  final List<NotificationItem> _notificationHistory = [];

  /// Called by the background isolate whenever TV settings change, so
  /// per-category filtering and image-preview stripping stay current.
  void updateSettings(TvSettings settings) {
    _settings = settings;
  }

  /// Plain indefinite DND toggle (Home screen's "Notification Receiving" /
  /// "Do Not Disturb" switches). Clears any timed session so a later timed
  /// expiry can't unexpectedly re-disable a manually-enabled DND.
  void toggleDndIndefinite() {
    isDndEnabled = !isDndEnabled;
    _dndUntilEpochMs = null;
  }

  /// Enables DND for [duration], auto-clearing once it elapses (checked from
  /// the background isolate's periodic tick via [checkDndExpiry]).
  void setDndForDuration(Duration duration) {
    isDndEnabled = true;
    _dndUntilEpochMs = DateTime.now().add(duration).millisecondsSinceEpoch;
    _log("DND enabled for $duration");
  }

  /// Auto-clears a timed DND session once its expiry has passed. No-op for
  /// an indefinite (manually toggled) DND session, since that has no expiry.
  void checkDndExpiry() {
    final until = _dndUntilEpochMs;
    if (until == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= until) {
      isDndEnabled = false;
      _dndUntilEpochMs = null;
      _log("Timed DND session expired, notifications resumed.");
    }
  }

  Stream<String?> get pairingPinStream => _pairingStateController.stream;
  Stream<List<ConnectedClient>> get pairedClientsStream =>
      _clientsController.stream;
  bool get isRunning => _isRunning;
  String? get currentPin =>
      _pairingSessions.values.isEmpty ? null : _pairingSessions.values.last.pin;
  List<ConnectedClient> get pairedClients => _pairedClients;
  Set<String> get activeTokens => _activeTokens;
  List<NotificationItem> get notificationHistory => _notificationHistory;
  Stream<Map<String, dynamic>> get overlayStream => _overlayController.stream;
  Stream<String> get logStream => _logController.stream;

  Future<void> init() async {
    await _loadPairedClients();
  }

  Future<void> _loadPairedClients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('paired_clients');
    if (jsonStr != null) {
      try {
        final List decoded = jsonDecode(jsonStr);
        _pairedClients.clear();
        for (final item in decoded) {
          _pairedClients.add(
            MirrorDevice.fromJson(Map<String, dynamic>.from(item)),
          );
        }
        _clientsController.add(List.from(_pairedClients));
      } catch (e) {
        debugPrint("Failed to load paired clients: $e");
      }
    }
  }

  Future<void> _savePairedClients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _pairedClients.map((c) => c.toJson()).toList();
    await prefs.setString('paired_clients', jsonEncode(list));
    _clientsController.add(List.from(_pairedClients));
  }

  /// Starts the HTTP+WebSocket server and mDNS broadcast. Route handling is
  /// split across the `_handle*Request` methods below to keep this focused
  /// on wiring routes and bringing the server/broadcast up.
  Future<void> startServer(String tvName, int port) async {
    if (_isRunning) return;

    final app = Router();
    app.post(MirrorProtocol.apiPair, _handlePairRequest);
    app.post(MirrorProtocol.apiPairConfirm, _handlePairConfirm);
    app.post(MirrorProtocol.apiPairQr, _handlePairQr);
    app.get(MirrorProtocol.wsPath, _handleWebSocketUpgrade);

    // Try the requested port first, then fall back across the next few so a
    // conflict (another app already bound it on the TV) doesn't kill the
    // server. mDNS and the QR code advertise whichever port actually bound.
    for (final candidate in List.generate(10, (i) => port + i)) {
      try {
        _server = await shelf_io.serve(
          app.call,
          InternetAddress.anyIPv4,
          candidate,
        );
        break;
      } catch (e) {
        _log("Port $candidate unavailable, trying next: $e");
      }
    }

    if (_server == null) {
      _log("Failed to start server: no free port in range $port-${port + 9}");
      _isRunning = false;
      return;
    }

    final actualPort = _server!.port;
    _log('HTTP Server running on port $actualPort');
    await _startMdnsBroadcast(tvName, actualPort);
    _isRunning = true;
  }

  Future<void> _startMdnsBroadcast(String tvName, int port) async {
    _broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: tvName,
        type: MirrorProtocol.mdnsType,
        port: port,
        attributes: {'device_name': tvName},
      ),
    );
    await _broadcast!.initialize();
    await _broadcast!.start();
    _log('mDNS Service Broadcasted: $tvName.${MirrorProtocol.mdnsType}');
  }

  /// HTTP Endpoint: Request pairing PIN.
  Future<shelf.Response> _handlePairRequest(shelf.Request request) async {
    final payload = await request.readAsString();
    try {
      final body = jsonDecode(payload);
      final deviceName = body['deviceName'] ?? 'Unknown Phone';
      final ip = (request.context['shelf.io.connection_info']
              as HttpConnectionInfo)
          .remoteAddress
          .address;

      final rng = Random();
      final pin = (rng.nextInt(9000) + 1000).toString();
      _pairingSessions[ip] = _PairingSession(pin: pin, deviceName: deviceName);
      _pairingStateController.add(pin);

      _log(
        "Pairing initiated from $deviceName ($ip). Generated PIN: $pin",
      );
      return shelf.Response.ok(jsonEncode({'status': 'pin_generated'}));
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Invalid payload');
    }
  }

  /// HTTP Endpoint: Confirm PIN and retrieve Token.
  Future<shelf.Response> _handlePairConfirm(shelf.Request request) async {
    final payload = await request.readAsString();
    try {
      final body = jsonDecode(payload);
      final pin = body['pin'] as String;
      final ip = (request.context['shelf.io.connection_info']
              as HttpConnectionInfo)
          .remoteAddress
          .address;
      final session = _pairingSessions[ip];

      if (session == null || pin != session.pin) {
        return shelf.Response.forbidden(jsonEncode({'error': 'invalid_pin'}));
      }

      final response = await _completePairing(
        request: request,
        deviceName: session.deviceName,
      );

      _pairingSessions.remove(ip);
      _pairingStateController.add(null);
      return response;
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Invalid payload');
    }
  }

  /// HTTP Endpoint: Confirm pairing via a scanned QR token.
  ///
  /// Unlike the PIN flow, [_qrToken] is proactively generated (not only
  /// after a phone starts pairing), so the QR code shown on the Pair Device
  /// screen is scannable from a cold start. The token is single-use: it's
  /// regenerated after every successful (or attempted) confirmation so a
  /// photo of an old QR code stops working.
  Future<shelf.Response> _handlePairQr(shelf.Request request) async {
    final payload = await request.readAsString();
    try {
      final body = jsonDecode(payload);
      final token = body['token'] as String?;
      final deviceName = body['deviceName'] as String? ?? 'Android Phone';

      if (token == null || token != _qrToken) {
        regenerateQrToken();
        return shelf.Response.forbidden(jsonEncode({'error': 'invalid_token'}));
      }

      final response = await _completePairing(
        request: request,
        deviceName: deviceName,
      );
      regenerateQrToken();
      return response;
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Invalid payload');
    }
  }

  /// Shared by both the PIN and QR pairing flows: mints an auth token, saves
  /// the paired client, and returns the `{status, token}` response body.
  Future<shelf.Response> _completePairing({
    required shelf.Request request,
    required String deviceName,
  }) async {
    final token = const Uuid().v4();
    final ip =
        request.context['shelf.io.connection_info'] as HttpConnectionInfo;
    final client = MirrorDevice(
      name: deviceName,
      ip: ip.remoteAddress.address,
      port: serverPort ?? MirrorProtocol.defaultPort,
      token: token,
    );

    _removeDuplicateClient(client);
    _pairedClients.add(client);
    await _savePairedClients();

    _log("Client paired successfully: ${client.name} (${client.ip})");
    return shelf.Response.ok(jsonEncode({'status': 'paired', 'token': token}));
  }

  /// Drops any existing paired client with the same name or IP as [client],
  /// closing its socket if it's currently connected, so re-pairing from the
  /// same phone doesn't leave stale duplicate entries behind.
  void _removeDuplicateClient(MirrorDevice client) {
    final duplicateIndex = _pairedClients.indexWhere(
      (c) => c.name == client.name || c.ip == client.ip,
    );
    if (duplicateIndex == -1) return;

    final oldClient = _pairedClients.removeAt(duplicateIndex);
    if (oldClient.token != null) {
      final socket = _socketToToken.entries
          .where((e) => e.value == oldClient.token)
          .map((e) => e.key)
          .firstOrNull;
      if (socket != null) {
        _socketToToken.remove(socket);
        _activeSockets.remove(socket);
        _activeTokens.remove(oldClient.token);
        socket.sink.close();
      }
    }
    _log(
      "Removed old duplicate client: ${oldClient.name} (${oldClient.ip})",
    );
  }

  /// WebSocket Endpoint: Real-time communication with a paired phone.
  FutureOr<shelf.Response> _handleWebSocketUpgrade(shelf.Request request) {
    final uri = request.requestedUri;
    final token = uri.queryParameters['token'];

    final isValidToken = _pairedClients.any((c) => c.token == token);
    if (!isValidToken) {
      _log("Unauthorized connection attempt to WebSocket. Token: $token");
      return shelf.Response.forbidden('Unauthorized');
    }

    return webSocketHandler((WebSocketChannel socket, _) {
      // If this token already has a live socket, close the old one first so a
      // reconnecting phone never leaves a stale duplicate behind. Without this,
      // a disconnect on the new socket keeps the token "active" via the old
      // (half-open) socket and the connected-client count never drops to 0.
      final existing = _socketToToken.entries
          .where((e) => e.value == token)
          .map((e) => e.key)
          .toList();
      for (final old in existing) {
        _socketToToken.remove(old);
        _activeSockets.remove(old);
        old.sink.close();
      }

      _activeSockets.add(socket);
      _activeTokens.add(token!);
      _socketToToken[socket] = token;
      _touchLastSynced(token);
      _log("WebSocket client connected. Token: $token");

      socket.stream.listen(
        (message) => _handleIncomingMessage(message as String, socket),
        onDone: () => _handleSocketClosed(socket, 'disconnected'),
        onError: (e) {
          _handleSocketClosed(socket, 'error: $e');
        },
      );

      socket.sink.add(jsonEncode({'status': 'connected'}));
    }).call(request);
  }

  /// Stamps the paired client owning [token] with the current time, so the
  /// Manage Devices screen can show "Last synced: ...".
  void _touchLastSynced(String token) {
    final index = _pairedClients.indexWhere((c) => c.token == token);
    if (index == -1) return;
    _pairedClients[index] = _pairedClients[index].copyWith(
      lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _savePairedClients();
  }

  /// Renames a paired client (Manage Devices screen action).
  Future<void> renameClient(String token, String newName) async {
    final index = _pairedClients.indexWhere((c) => c.token == token);
    if (index == -1) return;
    _pairedClients[index] = _pairedClients[index].copyWith(name: newName);
    await _savePairedClients();
  }

  void _handleSocketClosed(WebSocketChannel socket, String reason) {
    final t = _socketToToken.remove(socket);
    _activeSockets.remove(socket);
    // Only drop the token from the active set if no other socket still maps
    // to it. A phone may briefly hold two sockets with the same token (e.g.
    // the phone app restarted before its old TCP connection was torn down);
    // closing the stale one must not mark the live one as disconnected.
    if (t != null && !_socketToToken.containsValue(t)) {
      _activeTokens.remove(t);
    }
    _log("WebSocket client $reason. Token: $t");
  }

  /// Dispatches a decoded WebSocket message from a paired phone to the
  /// matching per-event handler below.
  void _handleIncomingMessage(String message, WebSocketChannel socket) {
    try {
      final payload = jsonDecode(message);
      final event = payload['event'] as String;
      final data = payload['data'];

      switch (event) {
        case MirrorProtocol.eventPing:
          _handlePing(socket);
        case MirrorProtocol.eventDisconnect:
          _handleClientDisconnect(socket);
        case MirrorProtocol.eventToggleDnd:
          _handleToggleDnd();
        case MirrorProtocol.eventSetDnd:
          _handleSetDnd(data);
        case MirrorProtocol.eventNotificationNew:
          _handleNewNotification(data);
        case MirrorProtocol.eventNotificationRemoved:
          _handleNotificationRemoved();
      }
    } catch (e) {
      _log("Failed to parse message: $e");
    }
  }

  void _handlePing(WebSocketChannel socket) {
    socket.sink.add(
      jsonEncode({
        'event': MirrorProtocol.eventPong,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  void _handleClientDisconnect(WebSocketChannel socket) {
    socket.sink.close();
    _handleSocketClosed(socket, 'requested disconnect');
  }

  void _handleToggleDnd() {
    isDndEnabled = !isDndEnabled;
    _log("DND mode toggled remotely to: $isDndEnabled");
  }

  void _handleSetDnd(Map<String, dynamic> data) {
    isDndEnabled = data['enabled'] as bool? ?? false;
    _log("DND mode set remotely to: $isDndEnabled");
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    if (isDndEnabled) {
      _log("DND mode enabled, ignoring notification.");
      return;
    }

    var item = NotificationItem.fromJson(data);

    final isCall =
        item.category == NotificationCategory.voiceCall ||
        item.category == NotificationCategory.videoCall;
    final isMessage = item.category == NotificationCategory.message;
    if (isCall && !_settings.callNotificationsEnabled) {
      _log("Call notifications disabled, ignoring notification.");
      return;
    }
    if (isMessage && !_settings.textNotificationsEnabled) {
      _log("Text notifications disabled, ignoring notification.");
      return;
    }

    if (!_settings.imagePreviewsEnabled) {
      item = item.copyWith(appIcon: null);
    }

    _notificationHistory.insert(0, item);
    if (_notificationHistory.length > 15) {
      _notificationHistory.removeLast();
    }

    _log(
      "Displaying notification: ${item.title} - ${item.text} from ${item.appName}",
    );
    _overlayController.add({
      'action': 'show',
      'title': item.title,
      'text': item.text,
      'appName': item.appName,
      'base64Icon': item.appIcon,
      'overlayPosition': item.overlayPosition,
      'overlayDuration': item.overlayDuration,
      'category': item.toJson()['category'],
    });
  }

  void _handleNotificationRemoved() {
    if (isDndEnabled) return;
    _log("Hiding notification overlay.");
    _overlayController.add({'action': 'hide'});
  }

  void clearHistory() {
    _notificationHistory.clear();
    _log("Notification history cleared.");
  }

  Future<void> stopServer() async {
    for (final socket in _activeSockets) {
      socket.sink.close();
    }
    _activeSockets.clear();

    await _broadcast?.stop();
    _broadcast = null;

    await _server?.close(force: true);
    _server = null;

    _isRunning = false;
  }

  Future<void> removeClient(ConnectedClient client) async {
    if (client.token != null) {
      final socket = _socketToToken.entries
          .where((e) => e.value == client.token)
          .map((e) => e.key)
          .firstOrNull;
      if (socket != null) {
        _socketToToken.remove(socket);
        _activeSockets.remove(socket);
        _activeTokens.remove(client.token!);
        socket.sink.close();
      }
    }
    _pairedClients.removeWhere((c) => c.token == client.token);
    await _savePairedClients();
  }
}
