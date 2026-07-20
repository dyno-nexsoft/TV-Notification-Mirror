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
  
  final StreamController<String?> _pairingStateController = StreamController<String?>.broadcast();
  final StreamController<List<ConnectedClient>> _clientsController = StreamController<List<ConnectedClient>>.broadcast();
  
  bool _isRunning = false;
  bool _isDndEnabled = false; // Do Not Disturb

  Stream<String?> get pairingPinStream => _pairingStateController.stream;
  Stream<List<ConnectedClient>> get pairedClientsStream => _clientsController.stream;
  bool get isRunning => _isRunning;
  String? get currentPin => _currentPin;
  List<ConnectedClient> get pairedClients => _pairedClients;
  bool get isDndEnabled => _isDndEnabled;

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
        print("WebSocket client connected.");

        socket.stream.listen(
          (message) {
            _handleIncomingMessage(message);
          },
          onDone: () {
            print("WebSocket client disconnected.");
            _activeSockets.remove(socket);
          },
          onError: (e) {
            print("WebSocket socket error: $e");
            _activeSockets.remove(socket);
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

  void _handleIncomingMessage(String message) {
    if (_isDndEnabled) {
      print("DND mode enabled, ignoring notification.");
      return;
    }

    try {
      final payload = jsonDecode(message);
      final event = payload['event'] as String;
      final data = payload['data'];

      if (event == 'notification_new') {
        final title = data['title'] ?? '';
        final text = data['text'] ?? '';
        final appName = data['appName'] ?? 'Notification';

        print("Displaying notification: $title - $text from $appName");
        OverlayService.showOverlay(
          title: title,
          text: text,
          appName: appName,
        );
      } else if (event == 'notification_removed') {
        print("Hiding notification overlay.");
        OverlayService.hideOverlay();
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
    _pairedClients.removeWhere((c) => c.token == client.token);
    await _savePairedClients();
  }
}
