import 'dart:async';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A TV discovered or connected from the phone's side of the mirror link.
typedef TVDevice = MirrorDevice;

/// Owns the phone's half of the mirror link: mDNS discovery, PIN pairing,
/// and the WebSocket connection (with auto-reconnect) used to relay
/// notifications and settings to the paired TV.
class ConnectorService {
  ConnectorService() {
    _loadSavedConnection();
  }
  final _storage = const FlutterSecureStorage();

  // mDNS Discovery
  BonsoirDiscovery? _discovery;
  final _devicesController = StreamController<List<TVDevice>>.broadcast();
  final _discoveredDevices = [];

  // WebSocket Connection
  WebSocketChannel? _wsChannel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  var _isConnecting = false;
  var _isConnected = false;
  var _reconnectAttempt = 0;

  String? _connectedTvIp;
  int? _connectedTvPort;
  String? _connectedTvName;

  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<List<TVDevice>> get devicesStream => _devicesController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  bool get isConnected => _isConnected;
  String? get connectedTvName => _connectedTvName;
  List<TVDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    _connectedTvIp = prefs.getString('connected_tv_ip');
    _connectedTvPort = prefs.getInt('connected_tv_port');
    _connectedTvName = prefs.getString('connected_tv_name');

    if (_connectedTvIp != null && _connectedTvPort != null) {
      debugPrint(
          "Found saved TV: $_connectedTvName at $_connectedTvIp:$_connectedTvPort. Reconnecting...");
      connectToSavedTv();
    }
  }

  // Start scanning for TV using mDNS
  Future<void> startScanning() async {
    _discoveredDevices.clear();
    _devicesController.add(List.from(_discoveredDevices));

    try {
      _discovery = BonsoirDiscovery(type: MirrorProtocol.mdnsType);
      await _discovery!.initialize();

      _discovery!.eventStream!.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          event.service.resolve(_discovery!.serviceResolver);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final service = event.service;
          final ip = service.hostAddress;
          final port = service.port;
          final name = service.name;

          if (ip != null) {
            final device = MirrorDevice(name: name, ip: ip, port: port);
            if (!_discoveredDevices.any((d) => d.ip == ip && d.port == port)) {
              _discoveredDevices.add(device);
              _devicesController.add(List.from(_discoveredDevices));
            }

            // Auto connect if this is our saved TV and we are currently offline
            if (!_isConnected &&
                _connectedTvIp == ip &&
                _connectedTvPort == port) {
              debugPrint(
                  "Discovered saved TV via mDNS ($name at $ip:$port). Triggering auto-connect...");
              connectToSavedTv();
            }
          }
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          final service = event.service;
          _discoveredDevices.removeWhere((d) => d.name == service.name);
          _devicesController.add(List.from(_discoveredDevices));
        }
      });

      await _discovery!.start();
    } catch (e) {
      debugPrint("mDNS discovery failed: $e");
    }
  }

  Future<void> stopScanning() async {
    await _discovery?.stop();
    _discovery = null;
  }

  // Step 1 of pairing: Request code
  Future<bool> startPairing(TVDevice device) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                'http://${device.ip}:${device.port}${MirrorProtocol.apiPair}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceName': 'Android Phone'}),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Failed to start pairing: $e");
      return false;
    }
  }

  // Step 2 of pairing: Confirm PIN
  Future<bool> confirmPairing(TVDevice device, String pin) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                'http://${device.ip}:${device.port}${MirrorProtocol.apiPairConfirm}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pin': pin, 'deviceName': 'Android Phone'}),
          )
          .timeout(const Duration(seconds: 5));

      return _completePairing(device, response);
    } catch (e) {
      debugPrint("Failed to confirm pairing: $e");
      return false;
    }
  }

  /// Pairs using a token scanned from the TV's QR code — skips the PIN step
  /// entirely. [rawQrData] is the raw string decoded from the QR (JSON:
  /// `{"ip", "port", "token"}`, see `TvPairDeviceScreen`).
  Future<bool> pairViaQr(String rawQrData) async {
    try {
      final decoded = jsonDecode(rawQrData) as Map<String, dynamic>;
      final ip = decoded['ip'] as String;
      final port = decoded['port'] as int;
      final token = decoded['token'] as String;
      final device = TVDevice(name: 'Android TV', ip: ip, port: port);

      final response = await http
          .post(
            Uri.parse('http://$ip:$port${MirrorProtocol.apiPairQr}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'deviceName': 'Android Phone'}),
          )
          .timeout(const Duration(seconds: 5));

      return await _completePairing(device, response);
    } catch (e) {
      debugPrint("Failed to pair via QR: $e");
      return false;
    }
  }

  /// Shared by [confirmPairing] and [pairViaQr]: on a successful `{status,
  /// token}` response, saves the auth token + connected-TV info and connects.
  Future<bool> _completePairing(TVDevice device, http.Response response) async {
    if (response.statusCode != 200) return false;

    final body = jsonDecode(response.body);
    final token = body['token'] as String;

    await _storage.write(key: 'auth_token_${device.ip}', value: token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('connected_tv_ip', device.ip);
    await prefs.setInt('connected_tv_port', device.port);
    await prefs.setString('connected_tv_name', device.name);

    _connectedTvIp = device.ip;
    _connectedTvPort = device.port;
    _connectedTvName = device.name;

    connectToSavedTv();
    return true;
  }

  // Establish WebSocket connection
  Future<bool> connectToSavedTv() async {
    if (_isConnected) return true;
    if (_isConnecting || _connectedTvIp == null || _connectedTvPort == null) {
      return false;
    }
    _isConnecting = true;

    final token = await _storage.read(key: 'auth_token_$_connectedTvIp');
    if (token == null) {
      _isConnecting = false;
      return false;
    }

    final wsUrl =
        'ws://$_connectedTvIp:$_connectedTvPort${MirrorProtocol.wsPath}?token=$token';
    debugPrint("Connecting WebSocket to $wsUrl");

    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await channel.ready.timeout(const Duration(seconds: 4));

      _wsChannel = channel;
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempt = 0;
      _connectionStateController.add(true);
      _reconnectTimer?.cancel();
      _startPingTimer();

      _wsChannel!.stream.listen(
        (message) {
          debugPrint("Received message from TV: $message");
        },
        onDone: () {
          debugPrint("WebSocket connection closed.");
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _handleDisconnect();
        },
      );

      return true;
    } catch (e) {
      debugPrint("WebSocket connection failed: $e");
      _handleDisconnect();
      return false;
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isConnected && _wsChannel != null) {
        try {
          _wsChannel!.sink.add(jsonEncode({
            'event': MirrorProtocol.eventPing,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        } catch (e) {
          debugPrint("Ping failed: $e");
          _handleDisconnect();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);
    _wsChannel = null;

    _reconnectTimer?.cancel();
    if (_connectedTvIp != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final backoff = Duration(
      seconds: (5 * (1 << _reconnectAttempt)).clamp(5, 60),
    );
    _reconnectAttempt++;
    debugPrint(
      "Scheduling reconnect attempt $_reconnectAttempt in ${backoff.inSeconds}s",
    );
    _reconnectTimer = Timer(backoff, () async {
      if (_isConnected) return;
      if (!_isConnecting) {
        debugPrint("Attempting automatic reconnect...");
        await connectToSavedTv();
      }
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
      debugPrint("Cannot send notification: WebSocket not connected.");
      return;
    }

    final itemJson = item.toJson();
    if (base64Icon != null) itemJson['appIcon'] = base64Icon;
    if (overlayPosition != null) itemJson['overlayPosition'] = overlayPosition;
    if (overlayDurationMs != null) {
      itemJson['overlayDuration'] = overlayDurationMs;
    }

    final payload = {
      'event': MirrorProtocol.eventNotificationNew,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': itemJson,
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    debugPrint("Notification sent to TV: ${item.title}");
  }

  // Send DND setting to TV
  void sendDndToggle(bool enabled) {
    if (!_isConnected || _wsChannel == null) {
      debugPrint("Cannot send DND toggle: WebSocket not connected.");
      return;
    }

    final payload = {
      'event': MirrorProtocol.eventSetDnd,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': {'enabled': enabled},
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    debugPrint("Remote DND change sent to TV: $enabled");
  }

  // Send cancel notification to TV
  void sendNotificationRemoved(String id, String packageName) {
    if (!_isConnected || _wsChannel == null) return;

    final payload = {
      'event': MirrorProtocol.eventNotificationRemoved,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': {
        'id': id,
        'packageName': packageName,
      },
    };

    _wsChannel!.sink.add(jsonEncode(payload));
    debugPrint("Notification remove request sent to TV for id: $id");
  }

  /// Immediately attempts to reconnect, resetting any exponential backoff.
  /// Called from UI when the app resumes from background.
  void checkConnection() {
    if (_isConnected) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    debugPrint("checkConnection: resetting backoff and reconnecting...");
    connectToSavedTv();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    if (_isConnected && _wsChannel != null) {
      try {
        _wsChannel!.sink.add(
            jsonEncode({'event': MirrorProtocol.eventDisconnect, 'data': {}}));
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
