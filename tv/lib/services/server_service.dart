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

/// A phone paired with (and optionally currently connected to) this TV.
typedef ConnectedClient = MirrorDevice;

/// Owns the TV's half of the mirror link: the HTTP pairing API, mDNS
/// broadcast, and the WebSocket server that receives and forwards
/// notifications from paired phones. Singleton so the background isolate
/// and UI isolate observe the same server state.
class ServerService {
  factory ServerService() => _instance;
  ServerService._internal();
  static final ServerService _instance = ServerService._internal();

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;

  String? _currentPin;
  String? _pairingDeviceName;

  final List<ConnectedClient> _pairedClients = [];
  final Set<WebSocketChannel> _activeSockets = {};
  final Set<String> _activeTokens = {};
  final Map<WebSocketChannel, String> _socketToToken = {};

  final StreamController<String?> _pairingStateController =
      StreamController<String?>.broadcast();
  final StreamController<List<ConnectedClient>> _clientsController =
      StreamController<List<ConnectedClient>>.broadcast();
  final StreamController<Map<String, dynamic>> _overlayController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isRunning = false;
  bool isDndEnabled = false;
  final List<NotificationItem> _notificationHistory = [];

  Stream<String?> get pairingPinStream => _pairingStateController.stream;
  Stream<List<ConnectedClient>> get pairedClientsStream =>
      _clientsController.stream;
  bool get isRunning => _isRunning;
  String? get currentPin => _currentPin;
  List<ConnectedClient> get pairedClients => _pairedClients;
  Set<String> get activeTokens => _activeTokens;
  List<NotificationItem> get notificationHistory => _notificationHistory;
  Stream<Map<String, dynamic>> get overlayStream => _overlayController.stream;

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
          _pairedClients
              .add(MirrorDevice.fromJson(Map<String, dynamic>.from(item)));
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
    app.post(MirrorProtocol.apiPairConfirm, (r) => _handlePairConfirm(r, port));
    app.get(MirrorProtocol.wsPath, _handleWebSocketUpgrade);

    try {
      _server = await shelf_io.serve(app.call, InternetAddress.anyIPv4, port);
      debugPrint('HTTP Server running on port ${_server!.port}');
      await _startMdnsBroadcast(tvName, _server!.port);
      _isRunning = true;
    } catch (e) {
      debugPrint("Failed to start server/broadcast: $e");
      _isRunning = false;
    }
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
    debugPrint('mDNS Service Broadcasted: $tvName.${MirrorProtocol.mdnsType}');
  }

  /// HTTP Endpoint: Request pairing PIN.
  Future<shelf.Response> _handlePairRequest(shelf.Request request) async {
    final payload = await request.readAsString();
    try {
      final body = jsonDecode(payload);
      _pairingDeviceName = body['deviceName'] ?? 'Unknown Phone';

      final rng = Random();
      _currentPin = (rng.nextInt(9000) + 1000).toString();
      _pairingStateController.add(_currentPin);

      debugPrint(
          "Pairing initiated from $_pairingDeviceName. Generated PIN: $_currentPin");
      return shelf.Response.ok(jsonEncode({'status': 'pin_generated'}));
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Invalid payload');
    }
  }

  /// HTTP Endpoint: Confirm PIN and retrieve Token.
  Future<shelf.Response> _handlePairConfirm(
      shelf.Request request, int port) async {
    final payload = await request.readAsString();
    try {
      final body = jsonDecode(payload);
      final pin = body['pin'] as String;

      if (_currentPin == null || pin != _currentPin) {
        return shelf.Response.forbidden(jsonEncode({'error': 'invalid_pin'}));
      }

      final token = const Uuid().v4();
      final ip =
          request.context['shelf.io.connection_info'] as HttpConnectionInfo;
      final client = MirrorDevice(
        name: _pairingDeviceName ?? 'Android Phone',
        ip: ip.remoteAddress.address,
        port: port,
        token: token,
      );

      _removeDuplicateClient(client);
      _pairedClients.add(client);
      await _savePairedClients();

      _currentPin = null;
      _pairingStateController.add(null);

      debugPrint("Client paired successfully: ${client.name} (${client.ip})");
      return shelf.Response.ok(
          jsonEncode({'status': 'paired', 'token': token}));
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Invalid payload');
    }
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
    debugPrint(
        "Removed old duplicate client: ${oldClient.name} (${oldClient.ip})");
  }

  /// WebSocket Endpoint: Real-time communication with a paired phone.
  FutureOr<shelf.Response> _handleWebSocketUpgrade(shelf.Request request) {
    final uri = request.requestedUri;
    final token = uri.queryParameters['token'];

    final isValidToken = _pairedClients.any((c) => c.token == token);
    if (!isValidToken) {
      debugPrint("Unauthorized connection attempt to WebSocket. Token: $token");
      return shelf.Response.forbidden('Unauthorized');
    }

    return webSocketHandler((WebSocketChannel socket, _) {
      _activeSockets.add(socket);
      _activeTokens.add(token!);
      _socketToToken[socket] = token;
      debugPrint("WebSocket client connected. Token: $token");

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

  void _handleSocketClosed(WebSocketChannel socket, String reason) {
    final t = _socketToToken.remove(socket);
    _activeSockets.remove(socket);
    if (t != null) _activeTokens.remove(t);
    debugPrint("WebSocket client $reason. Token: $t");
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
      debugPrint("Failed to parse message: $e");
    }
  }

  void _handlePing(WebSocketChannel socket) {
    socket.sink.add(jsonEncode({
      'event': MirrorProtocol.eventPong,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  void _handleClientDisconnect(WebSocketChannel socket) {
    socket.sink.close();
    _handleSocketClosed(socket, 'requested disconnect');
  }

  void _handleToggleDnd() {
    isDndEnabled = !isDndEnabled;
    debugPrint("DND mode toggled remotely to: $isDndEnabled");
  }

  void _handleSetDnd(Map<String, dynamic> data) {
    isDndEnabled = data['enabled'] as bool? ?? false;
    debugPrint("DND mode set remotely to: $isDndEnabled");
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    if (isDndEnabled) {
      debugPrint("DND mode enabled, ignoring notification.");
      return;
    }

    final item = NotificationItem.fromJson(data);
    _notificationHistory.insert(0, item);
    if (_notificationHistory.length > 15) {
      _notificationHistory.removeLast();
    }

    debugPrint("Displaying notification: ${item.title} - ${item.text} from ${item.appName}");
    _overlayController.add({
      'action': 'show',
      'title': item.title,
      'text': item.text,
      'appName': item.appName,
      'base64Icon': item.appIcon,
      'overlayPosition': item.overlayPosition,
      'overlayDuration': item.overlayDuration,
    });
  }

  void _handleNotificationRemoved() {
    if (isDndEnabled) return;
    debugPrint("Hiding notification overlay.");
    _overlayController.add({'action': 'hide'});
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
