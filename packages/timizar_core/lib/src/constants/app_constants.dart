class AppConstants {
  static const String appName = 'Timizar';
  static const String driverAppName = 'Timizar Driver';

  // Default Algeria focal points
  static const double defaultTiziOuzouLat = 36.7118;
  static const double defaultTiziOuzouLng = 4.0459;
  static const double defaultAlgiersLat = 36.7538;
  static const double defaultAlgiersLng = 3.0588;

  // Algeria map boundaries
  static const double algeriaMinLat = 18.9;
  static const double algeriaMaxLat = 37.1;
  static const double algeriaMinLng = -8.7;
  static const double algeriaMaxLng = 12.0;

  // Currency
  static const String currencyDzd = 'DZD';
  static const String currencyArabic = 'د.ج';
  static const String currencyFrench = 'DA';

  // Free Tier Throttling parameters
  static const int normalMovingIntervalSec = 5;
  static const int normalIdleIntervalSec = 15;
  static const double minDistanceFilterMeters = 15.0;
  static const double passengerRadiusMeters = 3000.0; // 3km

  // Default Base URL (can be overridden via environment or settings)
  static const String defaultApiBaseUrl = 'http://10.0.2.2:8787'; // Android emulator localhost or production URL
  static const String defaultWsBaseUrl = 'ws://10.0.2.2:8787';
}

