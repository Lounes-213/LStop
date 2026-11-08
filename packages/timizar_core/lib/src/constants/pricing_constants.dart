class PricingConstants {
  static const double baseFareDzd = 150.0;
  static const double perKmDzd = 40.0;
  static const double perMinuteDzd = 5.0;
  static const double minFareDzd = 200.0;

  static double calculateFare({
    required double distanceKm,
    required double durationMins,
  }) {
    final raw = baseFareDzd + (distanceKm * perKmDzd) + (durationMins * perMinuteDzd);
    final withMin = raw < minFareDzd ? minFareDzd : raw;
    // Round to nearest 10 DZD
    return (withMin / 10).ceil() * 10.0;
  }
}

