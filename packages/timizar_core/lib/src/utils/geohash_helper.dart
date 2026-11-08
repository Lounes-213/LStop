import 'dart:math' as math;

class GeohashHelper {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double latitude, double longitude, {int precision = 5}) {
    bool isEven = true;
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;
    int bit = 0;
    int ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  static ({double latitude, double longitude}) decode(String geohash) {
    bool isEven = true;
    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    for (int i = 0; i < geohash.length; i++) {
      final c = geohash[i];
      final cd = _base32.indexOf(c);
      if (cd == -1) continue;

      for (int j = 0; j < 5; j++) {
        final mask = 1 << (4 - j);
        if (isEven) {
          final mid = (lonMin + lonMax) / 2;
          if ((cd & mask) != 0) {
            lonMin = mid;
          } else {
            lonMax = mid;
          }
        } else {
          final mid = (latMin + latMax) / 2;
          if ((cd & mask) != 0) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        isEven = !isEven;
      }
    }

    return (
      latitude: (latMin + latMax) / 2,
      longitude: (lonMin + lonMax) / 2,
    );
  }

  /// Haversine formula to compute distance in meters
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }
}

