import 'dart:async';
import 'package:timizar_core/timizar_core.dart';

class BackgroundLocationService {
  final ApiClient _apiClient;
  final RealtimeClient _realtimeClient;
  final String driverId;

  Timer? _telemetryTimer;
  Timer? _throttleSyncTimer;

  bool _isMoving = false;
  int _movingIntervalSec = 5;
  int _idleIntervalSec = 15;
  double _minDistanceMeters = 15.0;

  double _currentLat = 0.0;
  double _currentLng = 0.0;
  double _lastSentLat = 0.0;
  double _lastSentLng = 0.0;
  double _heading = 0.0;
  double _speed = 0.0;

  BackgroundLocationService({
    required ApiClient apiClient,
    required RealtimeClient realtimeClient,
    required this.driverId,
  })  : _apiClient = apiClient,
        _realtimeClient = realtimeClient;

  void start(double initialLat, double initialLng) {
    _currentLat = initialLat;
    _currentLng = initialLng;
    _syncThrottleConfig();

    // Check budget guard throttle config every 10 minutes
    _throttleSyncTimer?.cancel();
    _throttleSyncTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _syncThrottleConfig();
    });

    _scheduleNextTick();
  }

  void stop() {
    _telemetryTimer?.cancel();
    _throttleSyncTimer?.cancel();
    _realtimeClient.sendDriverOffline(driverId);
  }

  void updatePosition({
    required double latitude,
    required double longitude,
    double heading = 0.0,
    double speed = 0.0,
  }) {
    _currentLat = latitude;
    _currentLng = longitude;
    _heading = heading;
    _speed = speed;

    // Moving if speed > 3 km/h
    final wasMoving = _isMoving;
    _isMoving = speed > 0.83; // 0.83 m/s = 3 km/h

    if (wasMoving != _isMoving) {
      _scheduleNextTick();
    }
  }

  void _scheduleNextTick() {
    _telemetryTimer?.cancel();
    final interval = _isMoving ? _movingIntervalSec : _idleIntervalSec;
    _telemetryTimer = Timer.periodic(Duration(seconds: interval), (_) {
      _tick();
    });
  }

  void _tick() {
    final dist = GeohashHelper.distanceMeters(_currentLat, _currentLng, _lastSentLat, _lastSentLng);
    if (dist >= _minDistanceMeters || _lastSentLat == 0.0) {
      _lastSentLat = _currentLat;
      _lastSentLng = _currentLng;

      _realtimeClient.sendDriverLocation(
        driverId: driverId,
        latitude: _currentLat,
        longitude: _currentLng,
        heading: _heading,
        speed: _speed,
        isMoving: _isMoving,
        isAvailable: true,
      );
    }
  }

  Future<void> _syncThrottleConfig() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.throttleConfig,
      parser: (data) => data as Map<String, dynamic>,
    );

    res.when(
      success: (data) {
        _movingIntervalSec = data['movingIntervalSeconds'] as int? ?? 5;
        _idleIntervalSec = data['idleIntervalSeconds'] as int? ?? 15;
        _minDistanceMeters = (data['minDistanceMeters'] as num? ?? 15.0).toDouble();
        AppLogger.i('Dynamic throttle synced: moving=${_movingIntervalSec}s, idle=${_idleIntervalSec}s');
        _scheduleNextTick();
      },
      failure: (_) {},
    );
  }
}

