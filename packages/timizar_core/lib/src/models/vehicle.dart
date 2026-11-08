class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;

  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
  });

  String get displayName => '$make $model ($color)';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String? ?? json['vehicle_id'] as String? ?? '',
      make: json['make'] as String? ?? json['vehicle_make'] as String? ?? '',
      model: json['model'] as String? ?? json['vehicle_model'] as String? ?? '',
      year: json['year'] as int? ?? 2020,
      color: json['color'] as String? ?? json['vehicle_color'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? json['licensePlate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make,
    'model': model,
    'year': year,
    'color': color,
    'licensePlate': licensePlate,
  };
}
