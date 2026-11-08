enum TripStatus {
  requested,
  offered,
  accepted,
  arriving,
  arrived,
  inProgress,
  completed,
  cancelledByPassenger,
  cancelledByDriver,
  timedOut;

  static TripStatus fromString(String status) {
    return switch (status.toLowerCase()) {
      'offered' => TripStatus.offered,
      'accepted' => TripStatus.accepted,
      'arriving' => TripStatus.arriving,
      'arrived' => TripStatus.arrived,
      'in_progress' || 'inprogress' => TripStatus.inProgress,
      'completed' => TripStatus.completed,
      'cancelled_by_passenger' => TripStatus.cancelledByPassenger,
      'cancelled_by_driver' => TripStatus.cancelledByDriver,
      'timed_out' || 'timedout' => TripStatus.timedOut,
      _ => TripStatus.requested,
    };
  }

  bool get isActive => this == TripStatus.accepted ||
      this == TripStatus.arriving ||
      this == TripStatus.arrived ||
      this == TripStatus.inProgress;

  bool get isFinished => this == TripStatus.completed ||
      this == TripStatus.cancelledByPassenger ||
      this == TripStatus.cancelledByDriver ||
      this == TripStatus.timedOut;
}

class Trip {
  final String id;
  final String passengerId;
  final String? driverId;
  final TripStatus status;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double distanceKm;
  final double durationMins;
  final double fareDzd;
  final DateTime requestedAt;
  final String? passengerName;
  final String? passengerPhone;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? licensePlate;

  const Trip({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMins,
    required this.fareDzd,
    required this.requestedAt,
    this.passengerName,
    this.passengerPhone,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.licensePlate,
  });

  String get formattedFare => '${fareDzd.toStringAsFixed(0)} DA';

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      passengerId: (json['passenger_id'] ?? json['passengerId']) as String,
      driverId: (json['driver_id'] ?? json['driverId']) as String?,
      status: TripStatus.fromString(json['status'] as String? ?? 'requested'),
      pickupLat: (json['pickup_lat'] ?? json['pickupLat'] as num).toDouble(),
      pickupLng: (json['pickup_lng'] ?? json['pickupLng'] as num).toDouble(),
      pickupAddress: (json['pickup_address'] ?? json['pickupAddress'] ?? '') as String,
      dropoffLat: (json['dropoff_lat'] ?? json['dropoffLat'] as num).toDouble(),
      dropoffLng: (json['dropoff_lng'] ?? json['dropoffLng'] as num).toDouble(),
      dropoffAddress: (json['dropoff_address'] ?? json['dropoffAddress'] ?? '') as String,
      distanceKm: (json['distance_km'] ?? json['distanceKm'] as num? ?? 0.0).toDouble(),
      durationMins: (json['duration_mins'] ?? json['durationMins'] as num? ?? 0.0).toDouble(),
      fareDzd: (json['fare_dzd'] ?? json['fareDzd'] as num? ?? 0.0).toDouble(),
      requestedAt: json['requested_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['requested_at'] as int) * 1000)
          : DateTime.now(),
      passengerName: json['passenger_name'] as String?,
      passengerPhone: json['passenger_phone'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble(),
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleColor: json['vehicle_color'] as String?,
      licensePlate: json['license_plate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'passengerId': passengerId,
    'driverId': driverId,
    'status': status.name,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'pickupAddress': pickupAddress,
    'dropoffLat': dropoffLat,
    'dropoffLng': dropoffLng,
    'dropoffAddress': dropoffAddress,
    'distanceKm': distanceKm,
    'durationMins': durationMins,
    'fareDzd': fareDzd,
    'requestedAt': requestedAt.millisecondsSinceEpoch ~/ 1000,
    'passengerName': passengerName,
    'passengerPhone': passengerPhone,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'driverRating': driverRating,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'licensePlate': licensePlate,
  };
}

