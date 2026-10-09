import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/route_optimizer.dart';

void main() {
  group('RouteOptimizer Permutation & Constraint Tests', () {
    test('Correctly orders stops respecting pickup-before-dropoff precedence', () {
      final stops = [
        const RouteStop(id: 'd1', bookingId: 'b1', isPickup: false, lat: 18.55, lng: 73.85, partySize: 1),
        const RouteStop(id: 'p1', bookingId: 'b1', isPickup: true, lat: 18.52, lng: 73.80, partySize: 1),
        const RouteStop(id: 'd2', bookingId: 'b2', isPickup: false, lat: 18.56, lng: 73.86, partySize: 1),
        const RouteStop(id: 'p2', bookingId: 'b2', isPickup: true, lat: 18.53, lng: 73.81, partySize: 1),
      ];

      final result = RouteOptimizer.optimize(
        stops: stops,
        vehicleCapacity: 4,
        distanceFn: (from, to) {
          // Euclidean distance approximation for testing
          final dLat = to.lat - from.lat;
          final dLng = to.lng - from.lng;
          return (dLat * dLat + dLng * dLng) * 100.0;
        },
      );

      expect(result.isFeasible, isTrue);
      final sequence = result.orderedStops;

      // Assert p1 comes before d1
      final p1Idx = sequence.indexWhere((s) => s.id == 'p1');
      final d1Idx = sequence.indexWhere((s) => s.id == 'd1');
      expect(p1Idx < d1Idx, isTrue);

      // Assert p2 comes before d2
      final p2Idx = sequence.indexWhere((s) => s.id == 'p2');
      final d2Idx = sequence.indexWhere((s) => s.id == 'd2');
      expect(p2Idx < d2Idx, isTrue);
    });

    test('Rejects permutation if simultaneous occupancy exceeds vehicle capacity', () {
      // 2 passengers each with party size 3 in a 4-seater car (total 6 seats needed if both onboard simultaneously)
      // BUT if p1 -> d1 -> p2 -> d2, max occupancy is 3 (feasible).
      // If p1 -> p2 -> d1 -> d2, occupancy becomes 3 + 3 = 6 (infeasible).
      final stops = [
        const RouteStop(id: 'p1', bookingId: 'b1', isPickup: true, lat: 0.0, lng: 0.0, partySize: 3),
        const RouteStop(id: 'd1', bookingId: 'b1', isPickup: false, lat: 1.0, lng: 0.0, partySize: 3),
        const RouteStop(id: 'p2', bookingId: 'b2', isPickup: true, lat: 2.0, lng: 0.0, partySize: 3),
        const RouteStop(id: 'd2', bookingId: 'b2', isPickup: false, lat: 3.0, lng: 0.0, partySize: 3),
      ];

      final result = RouteOptimizer.optimize(
        stops: stops,
        vehicleCapacity: 4,
        distanceFn: (from, to) => (to.lat - from.lat).abs(),
      );

      expect(result.isFeasible, isTrue);
      // The only feasible ordering that respects capacity <= 4 is: p1 -> d1 -> p2 -> d2
      expect(result.orderedStops.map((s) => s.id).toList(), equals(['p1', 'd1', 'p2', 'd2']));
    });

    test('Fails feasibility if even the best ordering exceeds capacity', () {
      // Single booking with party size 5 on a 4-seat car
      final stops = [
        const RouteStop(id: 'p1', bookingId: 'b1', isPickup: true, lat: 0.0, lng: 0.0, partySize: 5),
        const RouteStop(id: 'd1', bookingId: 'b1', isPickup: false, lat: 1.0, lng: 0.0, partySize: 5),
      ];

      final result = RouteOptimizer.optimize(
        stops: stops,
        vehicleCapacity: 4,
        distanceFn: (from, to) => 1.0,
      );

      expect(result.isFeasible, isFalse);
      expect(result.infeasibilityReason, isNotNull);
    });
  });
}
