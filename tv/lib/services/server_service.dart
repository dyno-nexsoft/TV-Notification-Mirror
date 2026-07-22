import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef ConnectedClient = MirrorDevice;

class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() => _instance;
  ServerService._internal();

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
  final List<Map<String, dynamic>> _notificationHistory = [];

  Stream<String?> get pairingPinStream => _pairingStateController.stream;
  Stream<List<ConnectedClient>> get pairedClientsStream =>
      _clientsController.stream;
  bool get isRunning => _isRunning;
  String? get currentPin => _currentPin;
  List<ConnectedClient> get pairedClients => _pairedClients;
  Set<String> get activeTokens => _activeTokens;
  List<Map<String, dynamic>> get notificationHistory => _notificationHistory;
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
          _pairedClients.add(MirrorDevice.fromMap(Map<String, dynamic>.from(item)));
        }
        _clientsController.add(List.from(_pairedClients));
      } catch (e) {
        debugPrint("Failed to load paired clients: $e");
      }
    }
  }

  Future<void> _savePairedClients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _pairedClients.map((c) => c.toMap()).toList();
    await prefs.setString('paired_clients', jsonEncode(list));
    _clientsController.add(List.from(_pairedClients));
  }

  // Start the server and mDNS broadcast
  Future<void> startServer(String tvName, int port) async {
    if (_isRunning) return;

    final app = Router();

    // HTTP Endpoint: Request pairing PIN
    app.post(MirrorProtocol.apiPair, (shelf.Request request) async {
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
    });

    // HTTP Endpoint: Confirm PIN and retrieve Token
    app.post(MirrorProtocol.apiPairConfirm, (shelf.Request request) async {
      final payload = await request.readAsString();
      try {
        final body = jsonDecode(payload);
        final pin = body['pin'] as String;

        if (_currentPin != null && pin == _currentPin) {
          final token = const Uuid().v4();
          final ip =
              request.context['shelf.io.connection_info'] as HttpConnectionInfo;

          final client = MirrorDevice(
            name: _pairingDeviceName ?? 'Android Phone',
            ip: ip.remoteAddress.address,
            port: port,
            token: token,
          );

          // Remove duplicate client (same IP or same device name)
          final duplicateIndex = _pairedClients.indexWhere(
            (c) => c.name == client.name || c.ip == client.ip,
          );
          if (duplicateIndex != -1) {
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

          _pairedClients.add(client);
          await _savePairedClients();

          _currentPin = null;
          _pairingStateController.add(null);

          debugPrint(
              "Client paired successfully: ${client.name} (${client.ip})");
          return shelf.Response.ok(
              jsonEncode({'status': 'paired', 'token': token}));
        } else {
          return shelf.Response.forbidden(jsonEncode({'error': 'invalid_pin'}));
        }
      } catch (e) {
        return shelf.Response.internalServerError(body: 'Invalid payload');
      }
    });

    // WebSocket Endpoint: Real-time communication
    app.get(MirrorProtocol.wsPath, (shelf.Request request) {
      final uri = request.requestedUri;
      final token = uri.queryParameters['token'];

      final isValidToken = _pairedClients.any((c) => c.token == token);
      if (!isValidToken) {
        debugPrint(
            "Unauthorized connection attempt to WebSocket. Token: $token");
        return shelf.Response.forbidden('Unauthorized');
      }

      return webSocketHandler((WebSocketChannel socket, _) {
        _activeSockets.add(socket);
        _activeTokens.add(token!);
        _socketToToken[socket] = token;
        debugPrint("WebSocket client connected. Token: $token");

        socket.stream.listen(
          (message) {
            _handleIncomingMessage(message as String, socket);
          },
          onDone: () {
            final t = _socketToToken.remove(socket);
            _activeSockets.remove(socket);
            if (t != null) _activeTokens.remove(t);
            debugPrint("WebSocket client disconnected. Token: $t");
          },
          onError: (e) {
            final t = _socketToToken.remove(socket);
            _activeSockets.remove(socket);
            if (t != null) _activeTokens.remove(t);
            debugPrint("WebSocket socket error: $e");
          },
        );

        socket.sink.add(jsonEncode({'status': 'connected'}));
      }).call(request);
    });

    try {
      _server = await shelf_io.serve(app.call, InternetAddress.anyIPv4, port);
      debugPrint('HTTP Server running on port ${_server!.port}');

      _broadcast = BonsoirBroadcast(
        service: BonsoirService(
          name: tvName,
          type: MirrorProtocol.mdnsType,
          port: _server!.port,
          attributes: {'device_name': tvName},
        ),
      );
      await _broadcast!.initialize();
      await _broadcast!.start();
      debugPrint('mDNS Service Broadcasted: $tvName.${MirrorProtocol.mdnsType}');

      _isRunning = true;
    } catch (e) {
      debugPrint("Failed to start server/broadcast: $e");
      _isRunning = false;
    }
  }

  void _handleIncomingMessage(String message, WebSocketChannel socket) {
    try {
      final payload = jsonDecode(message);
      final event = payload['event'] as String;
      final data = payload['data'];

      if (event == MirrorProtocol.eventPing) {
        socket.sink.add(jsonEncode({
          'event': MirrorProtocol.eventPong,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }));
        return;
      }

      if (event == MirrorProtocol.eventDisconnect) {
        final t = _socketToToken.remove(socket);
        _activeSockets.remove(socket);
        if (t != null) _activeTokens.remove(t);
        socket.sink.close();
        debugPrint("Client requested disconnect. Token: $t");
        return;
      }

      if (event == MirrorProtocol.eventToggleDnd) {
        isDndEnabled = !isDndEnabled;
        debugPrint("DND mode toggled remotely to: $isDndEnabled");
        return;
      }
      if (event == MirrorProtocol.eventSetDnd) {
        isDndEnabled = data['enabled'] as bool? ?? false;
        debugPrint("DND mode set remotely to: $isDndEnabled");
        return;
      }

      if (isDndEnabled) {
        debugPrint("DND mode enabled, ignoring notification.");
        return;
      }

      if (event == MirrorProtocol.eventNotificationNew) {
        final title = data['title'] ?? '';
        final text = data['text'] ?? '';
        final appName = data['appName'] ?? 'Notification';
        final base64Icon = data['appIcon'];
        final overlayPosition = data['overlayPosition'];
        final overlayDuration = data['overlayDuration'];

        _notificationHistory.insert(0, {
          'title': title,
          'text': text,
          'appName': appName,
          'packageName': data['packageName'] ?? '',
          'timestamp':
              data['postTime'] ?? DateTime.now().millisecondsSinceEpoch,
          'appIcon': base64Icon,
        });
        if (_notificationHistory.length > 15) {
          _notificationHistory.removeLast();
        }

        debugPrint("Displaying notification: $title - $text from $appName");
        _overlayController.add({
          'action': 'show',
          'title': title,
          'text': text,
          'appName': appName,
          'base64Icon': base64Icon,
          'overlayPosition': overlayPosition,
          'overlayDuration': overlayDuration,
        });
      } else if (event == MirrorProtocol.eventNotificationRemoved) {
        debugPrint("Hiding notification overlay.");
        _overlayController.add({'action': 'hide'});
      }
    } catch (e) {
      debugPrint("Failed to parse message: $e");
    }
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
