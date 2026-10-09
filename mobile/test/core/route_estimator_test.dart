import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';

void main() {
  group('RouteEstimatorService', () {
    late RouteEstimatorService estimator;

    setUp(() {
      estimator = const RouteEstimatorService();
    });

    test('calculates correct straight-line and road distance between Pune hubs', () {
      // Kothrud to Hinjawadi Phase 1 (~14 - 18 km road distance in Pune)
      final kothrud = PuneLandmarks.kothrud;
      final hinjawadi = PuneLandmarks.hinjawadiPhase1;

      final distance = estimator.calculateDistanceKm(kothrud, hinjawadi);
      expect(distance, greaterThan(10.0));
      expect(distance, lessThan(25.0));
    });

    test('calculates solo reference fare matching Test_cases.md formula (₹20 base + ₹10/km)', () {
      // ₹20 base + (12.0 km * ₹10/km) = ₹140
      expect(estimator.calculateSoloFare(12.0), equals(140.0));

      // ₹20 base + (0 km * ₹10/km) = ₹20
      expect(estimator.calculateSoloFare(0.0), equals(20.0));

      // ₹20 base + (15.5 km * ₹10/km) = ₹175.0 (rounded/calculated)
      expect(estimator.calculateSoloFare(15.5), equals(175.0));
    });

    test('calculates estimated duration assuming urban Pune traffic speed', () {
      // 12 km at ~24 km/h = 30 mins + 3 min buffer = ~33 mins
      final duration = estimator.calculateDurationMinutes(12.0);
      expect(duration, greaterThanOrEqualTo(25));
      expect(duration, lessThanOrEqualTo(45));
    });

    test('builds complete SoloRouteEstimate with polyline and formatted metrics', () {
      final estimate = estimator.estimateRoute(
        pickup: PuneLandmarks.shivajiNagar,
        dropoff: PuneLandmarks.swargate,
      );

      expect(estimate.pickup, equals(PuneLandmarks.shivajiNagar));
      expect(estimate.dropoff, equals(PuneLandmarks.swargate));
      expect(estimate.distanceKm, greaterThan(0));
      expect(estimate.durationMinutes, greaterThan(0));
      expect(estimate.referenceFare, greaterThan(20.0));
      expect(estimate.polylinePoints.length, greaterThanOrEqualTo(2));
      expect(estimate.formattedDistance, contains('km'));
      expect(estimate.formattedDuration, contains('min'));
      expect(estimate.formattedFare, contains('₹'));
    });

    test('provides key Pune preset landmarks', () {
      final presets = PuneLandmarks.all;
      expect(presets, isNotEmpty);
      expect(presets.any((l) => l.name.contains('Shivaji Nagar')), isTrue);
      expect(presets.any((l) => l.name.contains('Hinjawadi')), isTrue);
      expect(presets.any((l) => l.name.contains('Koregaon Park')), isTrue);
      expect(presets.any((l) => l.name.contains('Swargate')), isTrue);
    });
  });
}
