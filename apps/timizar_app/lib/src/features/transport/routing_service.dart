import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RoutingService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  /// Realistic Algerian collective transport duration (fourgon avec arrêts passagers)
  /// Average commercial fourgon speed is ~26 km/h in urban & RN12 sectors with stops
  static int calculateRealisticFourgonDuration(double distanceKm) {
    if (distanceKm <= 0.3) return 1;
    final rawMinutes = ((distanceKm / 26.0) * 60).round();
    return (rawMinutes + (distanceKm > 2.0 ? 3 : 1)).clamp(2, 240);
  }

  /// Single primary real road route from start to destination
  static Future<RouteResult?> getRoadRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await _dio.get<String>(url);
      if (response.statusCode == 200 && response.data != null) {
        final json = jsonDecode(response.data!) as Map<String, dynamic>;
        final rawRoutes = json['routes'] as List<dynamic>?;

        if (rawRoutes != null && rawRoutes.isNotEmpty) {
          final route = rawRoutes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords = geometry['coordinates'] as List<dynamic>;

          final points = coords.map((c) {
            final coord = c as List<dynamic>;
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          final distKm = double.parse(
            (((route['distance'] as num).toDouble()) / 1000.0)
                .toStringAsFixed(1),
          );
          final durationMins = calculateRealisticFourgonDuration(distKm);

          return RouteResult(
            points: points,
            distanceKm: distKm,
            durationMinutes: durationMins,
          );
        }
      }
    } catch (_) {
      // Fallback
    }

    return _buildFallbackRoute(start, end);
  }

  static RouteResult _buildFallbackRoute(LatLng start, LatLng end) {
    final points = <LatLng>[start];
    const steps = 18;
    for (int step = 1; step < steps; step++) {
      final t = step / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      final curve = 0.0012 * (1 - (2 * t - 1).abs());
      points.add(LatLng(lat + curve, lng + (curve * 0.5)));
    }
    points.add(end);

    final distKm = double.parse(
      (_calculateDistance(start, end) * 1.25).toStringAsFixed(1),
    );
    final duration = calculateRealisticFourgonDuration(distKm);

    return RouteResult(
      points: points,
      distanceKm: distKm,
      durationMinutes: duration,
    );
  }

  static double _calculateDistance(LatLng a, LatLng b) {
    const p = 0.017453292519943295;
    final c = 0.5 -
        ((b.latitude - a.latitude) * p).abs() / 2 +
        (1 - ((b.latitude - a.latitude) * p).abs()) *
            (1 - ((b.longitude - a.longitude) * p).abs()) /
            2;
    return 12742 * c.clamp(0.0001, 1.0);
  }
}
