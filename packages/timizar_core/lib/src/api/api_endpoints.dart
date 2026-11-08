class ApiEndpoints {
  // Auth
  static const String googleLogin = '/auth/google';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String userMe = '/users/me';
  static const String userFavorites = '/users/favorites';

  // Drivers
  static const String driverStatus = '/drivers/status';
  static const String driverOnboard = '/drivers/onboard';
  static const String driverShift = '/drivers/shift';
  static const String driverEarnings = '/drivers/earnings';

  // Trips
  static const String tripEstimate = '/trips/estimate';
  static const String tripRequest = '/trips/request';
  static const String tripHistory = '/trips/history/list';
  static String tripDetails(String id) => '/trips/$id';
  static String tripAccept(String id) => '/trips/$id/accept';
  static String tripReject(String id) => '/trips/$id/reject';
  static String tripStatus(String id) => '/trips/$id/status';
  static String tripRate(String id) => '/trips/$id/rate';

  // Maps & Location
  static const String search = '/search';
  static const String route = '/route';
  static const String reverseGeocode = '/reverse-geocode';
  static const String throttleConfig = '/throttle-config';
  static const String tiles = '/tiles';

  // Uploads
  static const String uploadDocument = '/uploads/document';

  // WebSockets
  static String wsZone(String geohash5, {required String userId, required String role, double? lat, double? lng}) {
    final query = 'userId=$userId&role=$role${lat != null ? '&lat=$lat&lng=$lng' : ''}';
    return '/ws/zone/$geohash5?$query';
  }

  static String wsTrip(String tripId, {required String userId, required String role}) {
    return '/ws/trip/$tripId?userId=$userId&role=$role';
  }
}

