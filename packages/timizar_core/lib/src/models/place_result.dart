class PlaceResult {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? municipality;

  const PlaceResult({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.municipality,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      id: json['id'] as String? ?? '${json['lat']},${json['lng']}',
      name: json['name'] as String? ?? 'Lieu',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      municipality: json['municipality'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lng': lng,
    'municipality': municipality,
  };
}

