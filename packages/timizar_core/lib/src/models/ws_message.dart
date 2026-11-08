import 'trip.dart';

sealed class WsMessage {
  final String type;
  const WsMessage(this.type);
}

class NearbyDriversMessage extends WsMessage {
  final List<Map<String, dynamic>> drivers;
  const NearbyDriversMessage(this.drivers) : super('nearby_drivers');
}

class DriverMovedMessage extends WsMessage {
  final String driverId;
  final double latitude;
  final double longitude;
  final double? heading;
  const DriverMovedMessage({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.heading,
  }) : super('driver_moved');
}

class DriverLeftMessage extends WsMessage {
  final String driverId;
  const DriverLeftMessage(this.driverId) : super('driver_left');
}

class RideOfferMessage extends WsMessage {
  final String tripId;
  final String pickupAddress;
  final String dropoffAddress;
  final double fareDzd;
  final double distanceKm;
  final double durationMins;
  final int expiresInSeconds;

  const RideOfferMessage({
    required this.tripId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fareDzd,
    required this.distanceKm,
    required this.durationMins,
    required this.expiresInSeconds,
  }) : super('ride_offer');

  factory RideOfferMessage.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>? ?? json;
    return RideOfferMessage(
      tripId: trip['id'] as String? ?? '',
      pickupAddress: trip['pickupAddress'] as String? ?? '',
      dropoffAddress: trip['dropoffAddress'] as String? ?? '',
      fareDzd: (trip['fareDzd'] as num? ?? 0.0).toDouble(),
      distanceKm: (trip['distanceKm'] as num? ?? 0.0).toDouble(),
      durationMins: (trip['durationMins'] as num? ?? 0.0).toDouble(),
      expiresInSeconds: trip['expiresInSeconds'] as int? ?? 15,
    );
  }
}

class TripUpdateMessage extends WsMessage {
  final Trip trip;
  const TripUpdateMessage(this.trip) : super('trip_update');
}

class UnknownWsMessage extends WsMessage {
  final Map<String, dynamic> raw;
  const UnknownWsMessage(this.raw) : super('unknown');
}

WsMessage parseWsMessage(Map<String, dynamic> json) {
  final type = json['type'] as String? ?? '';
  return switch (type) {
    'nearby_drivers' => NearbyDriversMessage(
        (json['drivers'] as List? ?? []).cast<Map<String, dynamic>>(),
      ),
    'driver_moved' => DriverMovedMessage(
        driverId: json['driver']?['driverId'] as String? ?? '',
        latitude: (json['driver']?['latitude'] as num? ?? 0.0).toDouble(),
        longitude: (json['driver']?['longitude'] as num? ?? 0.0).toDouble(),
        heading: (json['driver']?['heading'] as num?)?.toDouble(),
      ),
    'driver_left' => DriverLeftMessage(json['driverId'] as String? ?? ''),
    'ride_offer' => RideOfferMessage.fromJson(json),
    'trip_update' => TripUpdateMessage(
        Trip.fromJson(json['trip'] as Map<String, dynamic>),
      ),
    _ => UnknownWsMessage(json),
  };
}
