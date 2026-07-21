import 'dart:async';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/notification_item.dart';

class TVDevice {
  final String name;
  final String ip;
  final int port;

  TVDevice({required this.name, required this.ip, required this.port});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TVDevice &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          port == other.port;

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}

class ConnectorService {
  final _storage = const FlutterSecureStorage();
  
  // mDNS Discovery
  BonsoirDiscovery? _discovery;
  final StreamController<List<TVDevice>> _devicesController = StreamController<List<TVDevice>>.broadcast();
  final List<TVDevice> _discoveredDevices = [];

  // WebSocket Connection
  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _isConnected = false;
  
  String? _connectedTvIp;
  int? _connectedTvPort;
  String? _connectedTvName;

  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();

  ConnectorService() {
    _loadSavedConnection();
  }

  Stream<List<TVDevice>> get devicesStream => _devicesController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  bool get isConnected => _isConnected;
  String? get connectedTvName => _connectedTvName;

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedTvIp = prefs.getString('connected_tv_ip');
    _connectedTvPort = prefs.getInt('connected_tv_port');
    _connectedTvName = prefs.getString('connected_tv_name');

    if (_connectedTvIp != null && _connectedTvPort != null) {
      print("Found saved TV: $_connectedTvName at $_connectedTvIp:$_connectedTvPort. Reconnecting...");
      connectToSavedTv();
    }
  }

  // Start scanning for TV using mDNS
  Future<void> startScanning() async {
    _discoveredDevices.clear();
    _devicesController.add(List.from(_discoveredDevices));

    try {
      _discovery = BonsoirDiscovery(type: '_tvmirror._tcp');
      await _discovery!.initialize();

      _discovery!.eventStream!.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          event.service!.resolve(_discovery!.serviceResolver);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final service = event.service!;
          final ip = service.host;
          final port = service.port;
          final name = service.name;

          if (ip != null && port != null) {
            final device = TVDevice(name: name, ip: ip, port: port);
            if (!_discoveredDevices.any((d) => d.ip == ip && d.port == port)) {
              _discoveredDevices.add(device);
              _devicesController.add(List.from(_discoveredDevices));
            }
          }
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          final service = event.service!;
          _discoveredDevices.removeWhere((d) => d.name == service.name);
          _devicesController.add(List.from(_discoveredDevices));
        }
      });

      await _discovery!.start();
    } catch (e) {
      print("mDNS discovery failed: $e");
    }
  }

  Future<void> stopScanning() async {
    await _discovery?.stop();
    _discovery = null;
  }

  // Step 1 of pairing: Request code
  Future<bool> startPairing(TVDevice device) async {
    try {
      final response = await http.post(
        Uri.parse('http://${device.ip}:${device.port}/api/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceName': 'Android Phone'}),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print("Failed to start pairing: $e");
      return false;
    }
  }

  // Step 2 of pairing: Confirm PIN
  Future<bool> confirmPairing(TVDevice device, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('http://${device.ip}:${device.port}/api/pair/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin, 'deviceName': 'Android Phone'}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['token'] as String;

        // Save token & connection details
        await _storage.write(key: 'auth_token_${device.ip}', value: token);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('connected_tv_ip', device.ip);
        await prefs.setInt('connected_tv_port', device.port);
        await prefs.setString('connected_tv_name', device.name);

        _connectedTvIp = device.ip;
        _connectedTvPort = device.port;
        _connectedTvName = device.name;

        // Connect
        connectToSavedTv();
        return true;
      }
      return false;
    } catch (e) {
      print("Failed to confirm pairing: $e");
      return false;
    }
  }

  // Establish WebSocket connection
  Future<void> connectToSavedTv() async {
    if (_isConnecting || _connectedTvIp == null || _connectedTvPort == null) return;
    _isConnecting = true;

    final token = await _storage.read(key: 'auth_token_$_connectedTvIp');
    if (token == null) {
      _isConnecting = false;
      return;
    }

    final wsUrl = 'ws://$_connectedTvIp:$_connectedTvPort/ws?token=$token';
    print("Connecting WebSocket to $wsUrl");

    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _wsChannel!.stream.listen(
        (message) {
          print("Received message from TV: $message");
          _isConnected = true;
          _isConnecting = false;
          _connectionStateController.add(true);
        },
        onDone: () {
          print("WebSocket connection closed.");
          _handleDisconnect();
        },
        onError: (error) {
          print("WebSocket error: $error");
          _handleDisconnect();
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _connectionStateController.add(true);
      _reconnectTimer?.cancel();
    } catch (e) {
      print("WebSocket connection failed: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
    _wsChannel = null;

    // Retry connection after 10s
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      print("Attempting automatic reconnect...");
      connectToSavedTv();
    });
  }

  // Send notification to TV
  void sendNotification(
    NotificationItem item, {
    String? base64Icon,
    String? overlayPosition,
    int? overlayDurationMs,
  }) {
    if (!_isConnected || _wsChannel == null) {
      print("Cannot send notification: WebSocket not connected.");
      return;
    }

    final itemJson = item.toJson();
    if (base64Icon != null) {
      itemJson['appIcon'] = base64Icon;
    }
    if (overlayPosition != null) {
      itemJson['overlayPosition'] = overlayPosition;
    }
    if (overlayDurationMs != null) {
      itemJson['overlayDuration'] = overlayDurationMs;
    }

    final payload = {
      'event': 'notification_new',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': itemJson,
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    print("Notification sent to TV: ${item.title}");
  }

  // Send DND setting to TV
  void sendDndToggle(bool enabled) {
    if (!_isConnected || _wsChannel == null) {
      print("Cannot send DND toggle: WebSocket not connected.");
      return;
    }

    final payload = {
      'event': 'set_dnd',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': {'enabled': enabled},
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    print("Remote DND change sent to TV: $enabled");
  }

  // Send cancel notification to TV
  void sendNotificationRemoved(String id, String packageName) {
    if (!_isConnected || _wsChannel == null) return;

    final payload = {
      'event': 'notification_removed',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': {
        'id': id,
        'packageName': packageName,
      },
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    print("Notification remove request sent to TV for id: $id");
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    // Notify TV gracefully before closing so it updates online status immediately.
    if (_isConnected && _wsChannel != null) {
      try {
        _wsChannel!.sink.add(jsonEncode({'event': 'disconnect', 'data': {}}));
      } catch (_) {}
    }
    _wsChannel?.sink.close();
    _isConnected = false;
    _connectionStateController.add(false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('connected_tv_ip');
    await prefs.remove('connected_tv_port');
    await prefs.remove('connected_tv_name');

    if (_connectedTvIp != null) {
      await _storage.delete(key: 'auth_token_$_connectedTvIp');
    }

    _connectedTvIp = null;
    _connectedTvPort = null;
    _connectedTvName = null;
  }
}
