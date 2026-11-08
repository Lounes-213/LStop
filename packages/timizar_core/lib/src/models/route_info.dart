class RouteInfo {
  final double distanceKm;
  final double durationMins;
  final List<List<double>> coordinates; // [lat, lng]
  final String source;

  const RouteInfo({
    required this.distanceKm,
    required this.durationMins,
    required this.coordinates,
    required this.source,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'] as List? ?? [];
    final coords = rawCoords.map<List<double>>((point) {
      if (point is List) {
        return point.map((e) => (e as num).toDouble()).toList();
      }
      return [0.0, 0.0];
    }).toList();

    return RouteInfo(
      distanceKm: (json['distanceKm'] as num? ?? 0.0).toDouble(),
      durationMins: (json['durationMins'] as num? ?? 0.0).toDouble(),
      coordinates: coords,
      source: json['source'] as String? ?? 'tomtom',
    );
  }

  Map<String, dynamic> toJson() => {
    'distanceKm': distanceKm,
    'durationMins': durationMins,
    'coordinates': coordinates,
    'source': source,
  };
}

