import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LiveLocationState {
  final LatLng position;
  final double? heading;
  final double? speed;
  final bool hasPermission;
  final bool isLoading;
  final String? error;

  const LiveLocationState({
    required this.position,
    this.heading,
    this.speed,
    this.hasPermission = false,
    this.isLoading = true,
    this.error,
  });

  LiveLocationState copyWith({
    LatLng? position,
    double? heading,
    double? speed,
    bool? hasPermission,
    bool? isLoading,
    String? error,
  }) {
    return LiveLocationState(
      position: position ?? this.position,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      hasPermission: hasPermission ?? this.hasPermission,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LiveLocationNotifier extends StateNotifier<LiveLocationState> {
  StreamSubscription<Position>? _positionSubscription;

  // Default coordinates (Tizi Ouzou Centre) if GPS is pending or not available
  static const LatLng defaultLocation = LatLng(36.7118, 4.0459);

  LiveLocationNotifier()
      : super(const LiveLocationState(position: defaultLocation)) {
    initLiveLocation();
  }

  Future<void> initLiveLocation() async {
    state = state.copyWith(isLoading: true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'Le service de localisation est désactivé.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            hasPermission: false,
            error: 'Permission de localisation refusée.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          hasPermission: false,
          error: 'Permission de localisation refusée définitivement.',
        );
        return;
      }

      // Permissions granted
      state = state.copyWith(hasPermission: true);

      // 1. Get initial real position immediately
      final currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final realLatLng = LatLng(currentPos.latitude, currentPos.longitude);
      state = state.copyWith(
        position: realLatLng,
        heading: currentPos.heading,
        speed: currentPos.speed,
        isLoading: false,
      );

      // 2. Start continuous real-time live stream
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3, // Update every 3 meters
        ),
      ).listen(
        (pos) {
          if (!mounted) return;
          state = state.copyWith(
            position: LatLng(pos.latitude, pos.longitude),
            heading: pos.heading,
            speed: pos.speed,
            isLoading: false,
          );
        },
        onError: (e) {
          if (kDebugMode) {
            print('Live location stream error: $e');
          }
        },
      );
    } catch (e) {
      // Graceful fallback to default Algerian location without crashing
      state = state.copyWith(
        isLoading: false,
        position: defaultLocation,
      );
    }
  }

  Future<LatLng> refreshCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final newPos = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(position: newPos, isLoading: false);
      return newPos;
    } catch (_) {
      return state.position;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final liveLocationProvider =
    StateNotifierProvider<LiveLocationNotifier, LiveLocationState>((ref) {
  return LiveLocationNotifier();
});
