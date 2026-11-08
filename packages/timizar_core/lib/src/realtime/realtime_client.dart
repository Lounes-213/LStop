import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/ws_message.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class RealtimeClient {
  final String baseWsUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  int _reconnectAttempts = 0;

  final _messageController = StreamController<WsMessage>.broadcast();
  Stream<WsMessage> get messageStream => _messageController.stream;

  String? _currentUrl;

  RealtimeClient({String? baseWsUrl})
      : baseWsUrl = baseWsUrl ?? AppConstants.defaultWsBaseUrl;

  void connectToZone({
    required String geohash5,
    required String userId,
    required String role,
    double? lat,
    double? lng,
  }) {
    final query = 'userId=$userId&role=$role${lat != null ? '&lat=$lat&lng=$lng' : ''}';
    final url = '$baseWsUrl/ws/zone/$geohash5?$query';
    _connect(url);
  }

  void connectToTrip({
    required String tripId,
    required String userId,
    required String role,
  }) {
    final url = '$baseWsUrl/ws/trip/$tripId?userId=$userId&role=$role';
    _connect(url);
  }

  void _connect(String url) {
    if (_isDisposed) return;
    _currentUrl = url;
    _disconnectInternal();

    AppLogger.i('Connecting WebSocket to: $url');
    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0; // reset backoff on message received
          _handleRawMessage(data);
        },
        onError: (error) {
          AppLogger.w('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          AppLogger.i('WebSocket connection closed');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      _startHeartbeat();
    } catch (e) {
      AppLogger.e('WebSocket connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleRawMessage(dynamic data) {
    if (data is! String) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final msg = parseWsMessage(json);
      _messageController.add(msg);
    } catch (e) {
      AppLogger.w('Could not parse WebSocket message: $data');
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        AppLogger.w('Error sending WS message: $e');
      }
    }
  }

  void sendDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    bool isMoving = false,
    bool isAvailable = true,
  }) {
    send({
      'type': 'driver_location',
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'isMoving': isMoving,
      'isAvailable': isAvailable,
    });
  }

  void sendDriverOffline(String driverId) {
    send({
      'type': 'driver_offline',
      'driverId': driverId,
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // 25s ping keeps connection alive without triggering excess DO compute
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed || _currentUrl == null) return;
    _heartbeatTimer?.cancel();

    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts * 2).clamp(1, 15);
    AppLogger.i('Reconnecting in $backoffSeconds seconds (attempt $_reconnectAttempts)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (!_isDisposed && _currentUrl != null) {
        _connect(_currentUrl!);
      }
    });
  }

  void _disconnectInternal() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _currentUrl = null;
    _reconnectTimer?.cancel();
    _disconnectInternal();
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _messageController.close();
  }
}

