import 'package:flutter_test/flutter_test.dart';
import 'package:timizar_core/timizar_core.dart';

void main() {
  group('GeohashHelper Unit Tests', () {
    test('encodes and decodes Tizi Ouzou coordinates', () {
      const lat = 36.7118;
      const lng = 4.0459;
      final hash = GeohashHelper.encode(lat, lng, precision: 5);

      expect(hash.length, 5);
      final decoded = GeohashHelper.decode(hash);
      expect((decoded.latitude - lat).abs(), lessThan(0.05));
      expect((decoded.longitude - lng).abs(), lessThan(0.05));
    });

    test('calculates Haversine distance in meters', () {
      // Tizi Ouzou center to nearby town
      final dist = GeohashHelper.distanceMeters(36.7118, 4.0459, 36.7583, 4.0847);
      expect(dist, greaterThan(5000));
      expect(dist, lessThan(8000));
    });
  });

  group('Algerian Pricing Unit Tests', () {
    test('enforces 200 DA minimum fare for ultra-short trips', () {
      final fare = PricingConstants.calculateFare(distanceKm: 0.4, durationMins: 2);
      expect(fare, 200.0);
    });

    test('rounds up to nearest 10 DA for standard trips', () {
      final fare = PricingConstants.calculateFare(distanceKm: 8.5, durationMins: 15);
      expect(fare % 10, 0.0);
      expect(fare, greaterThan(200.0));
    });
  });

  group('Result Type Functional Pattern', () {
    test('Success returns data and isSuccess is true', () {
      const Result<int, String> res = Success(42);
      expect(res.isSuccess, true);
      expect(res.isFailure, false);
      expect(res.dataOrNull, 42);
      expect(res.errorOrNull, isNull);
    });

    test('Failure returns error and isFailure is true', () {
      const Result<int, String> res = Failure('Network error');
      expect(res.isSuccess, false);
      expect(res.isFailure, true);
      expect(res.dataOrNull, isNull);
      expect(res.errorOrNull, 'Network error');
    });
  });

  group('DTO Serialization Tests', () {
    test('User serialization and deserialization', () {
      const user = User(
        id: 'u1',
        email: 'passenger@timizar.dz',
        name: 'Lounes Ait',
        role: UserRole.passenger,
      );

      final json = user.toJson();
      final parsed = User.fromJson(json);

      expect(parsed.id, 'u1');
      expect(parsed.email, 'passenger@timizar.dz');
      expect(parsed.name, 'Lounes Ait');
      expect(parsed.role, UserRole.passenger);
    });

    test('Trip DTO status parsing', () {
      expect(TripStatus.fromString('accepted'), TripStatus.accepted);
      expect(TripStatus.fromString('in_progress'), TripStatus.inProgress);
      expect(TripStatus.fromString('timed_out'), TripStatus.timedOut);
    });
  });
}
