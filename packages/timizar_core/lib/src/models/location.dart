class DriverLocation {
  final String driverId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final bool isAvailable;
  final DateTime? timestamp;

  const DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.isAvailable = true,
    this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      driverId: (json['driverId'] ?? json['driver_id'] ?? '') as String,
      latitude: (json['latitude'] ?? json['lat'] as num).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? json['is_available'] as bool? ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'speed': speed,
    'isAvailable': isAvailable,
    'timestamp': (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
  };
}

class UserCoordinate {
  final double latitude;
  final double longitude;
  final String? address;

  const UserCoordinate({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory UserCoordinate.fromJson(Map<String, dynamic> json) {
    return UserCoordinate(
      latitude: (json['lat'] ?? json['latitude'] as num).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'address': address,
  };
}
