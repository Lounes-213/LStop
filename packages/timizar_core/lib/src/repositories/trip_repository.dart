import '../models/trip.dart';
import '../models/fare_breakdown.dart';
import '../models/route_info.dart';
import '../utils/result.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

abstract interface class TripRepository {
  Future<Result<({FareBreakdown fare, RouteInfo route}), String>> estimateTrip({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  });

  Future<Result<String, String>> requestTrip({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
  });

  Future<Result<Trip, String>> getTripDetails(String tripId);
  Future<Result<void, String>> acceptTrip(String tripId);
  Future<Result<void, String>> rejectTrip(String tripId);
  Future<Result<void, String>> updateTripStatus(String tripId, String status);
  Future<Result<void, String>> rateTrip(String tripId, int score, {String? comment});
  Future<Result<List<Trip>, String>> getTripHistory();
}

class TripRepositoryImpl implements TripRepository {
  final ApiClient _apiClient;

  TripRepositoryImpl([ApiClient? apiClient]) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<({FareBreakdown fare, RouteInfo route}), String>> estimateTrip({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.tripEstimate,
      data: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) {
        final fare = FareBreakdown.fromJson(data['fare'] as Map<String, dynamic>);
        final route = RouteInfo.fromJson(data['route'] as Map<String, dynamic>);
        return Success((fare: fare, route: route));
      },
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<String, String>> requestTrip({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
  }) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.tripRequest,
      data: {
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'dropoffAddress': dropoffAddress,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) => Success(data['tripId'] as String),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<Trip, String>> getTripDetails(String tripId) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.tripDetails(tripId),
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) => Success(Trip.fromJson(data['trip'] as Map<String, dynamic>)),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<void, String>> acceptTrip(String tripId) async {
    final res = await _apiClient.post(ApiEndpoints.tripAccept(tripId));
    return res.when(
      success: (_) => const Success(null),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<void, String>> rejectTrip(String tripId) async {
    final res = await _apiClient.post(ApiEndpoints.tripReject(tripId));
    return res.when(
      success: (_) => const Success(null),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<void, String>> updateTripStatus(String tripId, String status) async {
    final res = await _apiClient.post(
      ApiEndpoints.tripStatus(tripId),
      data: {'status': status},
    );
    return res.when(
      success: (_) => const Success(null),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<void, String>> rateTrip(String tripId, int score, {String? comment}) async {
    final res = await _apiClient.post(
      ApiEndpoints.tripRate(tripId),
      data: {'score': score, 'comment': comment},
    );
    return res.when(
      success: (_) => const Success(null),
      failure: (err) => Failure(err),
    );
  }

  @override
  Future<Result<List<Trip>, String>> getTripHistory() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.tripHistory,
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) {
        final list = (data['trips'] as List? ?? [])
            .map((item) => Trip.fromJson(item as Map<String, dynamic>))
            .toList();
        return Success(list);
      },
      failure: (err) => Failure(err),
    );
  }
}

