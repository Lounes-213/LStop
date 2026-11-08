class FareBreakdown {
  final double baseFareDzd;
  final double distanceFareDzd;
  final double timeFareDzd;
  final double totalFareDzd;
  final double distanceKm;
  final int durationMins;

  const FareBreakdown({
    required this.baseFareDzd,
    required this.distanceFareDzd,
    required this.timeFareDzd,
    required this.totalFareDzd,
    required this.distanceKm,
    required this.durationMins,
  });

  String get formattedFare => '${totalFareDzd.toStringAsFixed(0)} DA';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMins min';

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFareDzd: (json['baseFareDzd'] as num? ?? 150).toDouble(),
      distanceFareDzd: (json['distanceFareDzd'] as num? ?? 0).toDouble(),
      timeFareDzd: (json['timeFareDzd'] as num? ?? 0).toDouble(),
      totalFareDzd: (json['totalFareDzd'] as num? ?? 200).toDouble(),
      distanceKm: (json['distanceKm'] as num? ?? 1.0).toDouble(),
      durationMins: json['durationMins'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseFareDzd': baseFareDzd,
    'distanceFareDzd': distanceFareDzd,
    'timeFareDzd': timeFareDzd,
    'totalFareDzd': totalFareDzd,
    'distanceKm': distanceKm,
    'durationMins': durationMins,
  };
}
