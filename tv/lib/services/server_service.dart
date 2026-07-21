import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bonsoir/bonsoir.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'overlay_service.dart';

class ConnectedClient {
  final String deviceName;
  final String ip;
  final String token;

  ConnectedClient({required this.deviceName, required this.ip, required this.token});
}

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
  // Tracks which paired-client tokens currently have an active WebSocket.
  final Set<String> _activeTokens = {};
  // Maps active socket → token so we can look up on disconnect.
  final Map<WebSocketChannel, String> _socketToToken = {};
  
  final StreamController<String?> _pairingStateController = StreamController<String?>.broadcast();
  final StreamController<List<ConnectedClient>> _clientsController = StreamController<List<ConnectedClient>>.broadcast();
  final StreamController<Map<String, dynamic>> _overlayController = StreamController<Map<String, dynamic>>.broadcast();
  
  bool _isRunning = false;
  bool _isDndEnabled = false; // Do Not Disturb
  final List<Map<String, dynamic>> _notificationHistory = [];

  Stream<String?> get pairingPinStream => _pairingStateController.stream;
  Stream<List<ConnectedClient>> get pairedClientsStream => _clientsController.stream;
  bool get isRunning => _isRunning;
  String? get currentPin => _currentPin;
  List<ConnectedClient> get pairedClients => _pairedClients;
  bool get isDndEnabled => _isDndEnabled;
  Set<String> get activeTokens => _activeTokens;
  List<Map<String, dynamic>> get notificationHistory => _notificationHistory;
  Stream<Map<String, dynamic>> get overlayStream => _overlayController.stream;

  set isDndEnabled(bool value) {
    _isDndEnabled = value;
  }

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
        for (var item in decoded) {
          _pairedClients.add(ConnectedClient(
            deviceName: item['deviceName'] ?? '',
            ip: item['ip'] ?? '',
            token: item['token'] ?? '',
          ));
        }
        _clientsController.add(List.from(_pairedClients));
      } catch (e) {
        print("Failed to load paired clients: $e");
      }
    }
  }

  Future<void> _savePairedClients() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _pairedClients.map((c) => {
      'deviceName': c.deviceName,
      'ip': c.ip,
      'token': c.token,
    }).toList();
    await prefs.setString('paired_clients', jsonEncode(list));
    _clientsController.add(List.from(_pairedClients));
  }

  // Start the server and mDNS broadcast
  Future<void> startServer(String tvName, int port) async {
    if (_isRunning) return;

    final app = Router();

    // HTTP Endpoint: Request pairing PIN
    app.post('/api/pair', (shelf.Request request) async {
      final payload = await request.readAsString();
      try {
        final body = jsonDecode(payload);
        _pairingDeviceName = body['deviceName'] ?? 'Unknown Phone';
        
        // Generate random 4-digit PIN
        final rng = Random();
        _currentPin = (rng.nextInt(9000) + 1000).toString();
        _pairingStateController.add(_currentPin);
        
        print("Pairing initiated from $_pairingDeviceName. Generated PIN: $_currentPin");
        return shelf.Response.ok(jsonEncode({'status': 'pin_generated'}));
      } catch (e) {
        return shelf.Response.internalServerError(body: 'Invalid payload');
      }
    });

    // HTTP Endpoint: Confirm PIN and retrieve Token
    app.post('/api/pair/confirm', (shelf.Request request) async {
      final payload = await request.readAsString();
      try {
        final body = jsonDecode(payload);
        final pin = body['pin'] as String;
        
        if (pin == _currentPin && _currentPin != null) {
          final token = const Uuid().v4();
          final ip = request.context['shelf.io.connection_info'] as HttpConnectionInfo;
          
          final client = ConnectedClient(
            deviceName: _pairingDeviceName ?? 'Android Phone',
            ip: ip.remoteAddress.address,
            token: token,
          );
          
          // Remove duplicate client (same IP or same device name)
          final duplicateIndex = _pairedClients.indexWhere(
            (c) => c.deviceName == client.deviceName || c.ip == client.ip,
          );
          if (duplicateIndex != -1) {
            final oldClient = _pairedClients.removeAt(duplicateIndex);
            // Close active socket if client is currently connected.
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
            print("Removed old duplicate client: ${oldClient.deviceName} (${oldClient.ip})");
          }

          // Save client
          _pairedClients.add(client);
          await _savePairedClients();
          
          // Clear PIN
          _currentPin = null;
          _pairingStateController.add(null);
          
          print("Client paired successfully: ${client.deviceName} (${client.ip})");
          return shelf.Response.ok(jsonEncode({'status': 'paired', 'token': token}));
        } else {
          return shelf.Response.forbidden(jsonEncode({'error': 'invalid_pin'}));
        }
      } catch (e) {
        return shelf.Response.internalServerError(body: 'Invalid payload');
      }
    });

    // WebSocket Endpoint: Real-time communication
    app.get('/ws', (shelf.Request request) {
      final uri = request.requestedUri;
      final token = uri.queryParameters['token'];

      // Authenticate token
      final isValidToken = _pairedClients.any((c) => c.token == token);
      if (!isValidToken) {
        print("Unauthorized connection attempt to WebSocket. Token: $token");
        return shelf.Response.forbidden('Unauthorized');
      }

      return webSocketHandler((WebSocketChannel socket, _) {
        _activeSockets.add(socket);
        _activeTokens.add(token!);
        _socketToToken[socket] = token!;
        print("WebSocket client connected. Token: $token");

        socket.stream.listen(
          (message) {
            _handleIncomingMessage(message, socket);
          },
          onDone: () {
            final t = _socketToToken.remove(socket);
            _activeSockets.remove(socket);
            if (t != null) _activeTokens.remove(t);
            print("WebSocket client disconnected. Token: $t");
          },
          onError: (e) {
            final t = _socketToToken.remove(socket);
            _activeSockets.remove(socket);
            if (t != null) _activeTokens.remove(t);
            print("WebSocket socket error: $e");
          },
        );

        socket.sink.add(jsonEncode({'status': 'connected'}));
      })(request);
    });

    try {
      // Bind to all interfaces
      _server = await shelf_io.serve(app, InternetAddress.anyIPv4, port);
      print('HTTP Server running on port ${_server!.port}');

      // Register mDNS
      _broadcast = BonsoirBroadcast(
        service: BonsoirService(
          name: tvName,
          type: '_tvmirror._tcp',
          port: _server!.port,
          attributes: {'device_name': tvName},
        ),
      );
      await _broadcast!.initialize();
      await _broadcast!.start();
      print('mDNS Service Broadcasted: $tvName._tvmirror._tcp');

      _isRunning = true;
    } catch (e) {
      print("Failed to start server/broadcast: $e");
      _isRunning = false;
    }
  }

  void _handleIncomingMessage(String message, WebSocketChannel socket) {
    try {
      final payload = jsonDecode(message);
      final event = payload['event'] as String;
      final data = payload['data'];

      if (event == 'disconnect') {
        // Phone is politely disconnecting — remove its socket immediately.
        final t = _socketToToken.remove(socket);
        _activeSockets.remove(socket);
        if (t != null) _activeTokens.remove(t);
        socket.sink.close();
        print("Client requested disconnect. Token: $t");
        return;
      }

      // Handle Remote DND Control
      if (event == 'toggle_dnd') {
        _isDndEnabled = !_isDndEnabled;
        print("DND mode toggled remotely to: $_isDndEnabled");
        return;
      }
      if (event == 'set_dnd') {
        _isDndEnabled = data['enabled'] as bool? ?? false;
        print("DND mode set remotely to: $_isDndEnabled");
        return;
      }

      if (_isDndEnabled) {
        print("DND mode enabled, ignoring notification.");
        return;
      }

      if (event == 'notification_new') {
        final title = data['title'] ?? '';
        final text = data['text'] ?? '';
        final appName = data['appName'] ?? 'Notification';
        final base64Icon = data['appIcon'];
        final overlayPosition = data['overlayPosition'];
        final overlayDuration = data['overlayDuration'];

        // Add to history (keep last 15)
        _notificationHistory.insert(0, {
          'title': title,
          'text': text,
          'appName': appName,
          'packageName': data['packageName'] ?? '',
          'timestamp': data['postTime'] ?? DateTime.now().millisecondsSinceEpoch,
          'appIcon': base64Icon,
        });
        if (_notificationHistory.length > 15) {
          _notificationHistory.removeLast();
        }

        print("Displaying notification: $title - $text from $appName");
        _overlayController.add({
          'action': 'show',
          'title': title,
          'text': text,
          'appName': appName,
          'base64Icon': base64Icon,
          'overlayPosition': overlayPosition,
          'overlayDuration': overlayDuration,
        });
      } else if (event == 'notification_removed') {
        print("Hiding notification overlay.");
        _overlayController.add({
          'action': 'hide',
        });
      }
    } catch (e) {
      print("Failed to parse message: $e");
    }
  }

  Future<void> stopServer() async {
    // Close all sockets
    for (var socket in _activeSockets) {
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
    // Close active socket if client is currently connected.
    final socket = _socketToToken.entries
        .where((e) => e.value == client.token)
        .map((e) => e.key)
        .firstOrNull;
    if (socket != null) {
      _socketToToken.remove(socket);
      _activeSockets.remove(socket);
      _activeTokens.remove(client.token);
      socket.sink.close();
    }
    _pairedClients.removeWhere((c) => c.token == client.token);
    await _savePairedClients();
  }
}
