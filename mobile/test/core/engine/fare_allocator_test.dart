import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';

void main() {
  group('FareAllocator Integration Tests', () {
    test('Allocates fares successfully when detours are within 15%', () {
      const allocator = FareAllocator();

      final candidates = [
        const BookingCandidate(id: 'A', partySize: 1, soloKm: 8.0, sharedKm: 8.8), // 10% detour
        const BookingCandidate(id: 'B', partySize: 1, soloKm: 9.0, sharedKm: 9.9), // 10% detour
      ];

      final result = allocator.allocate(
        candidates: candidates,
        totalSharedKm: 12.0,
        coalitionDistancesKm: {
          'A': 8.0,
          'B': 9.0,
          'A,B': 12.0,
        },
      );

      expect(result.isFeasible, isTrue);
      expect(result.allocatedFares['A'], equals(65.0));
      expect(result.allocatedFares['B'], equals(75.0));
      expect(result.totalTripCost, equals(140.0));
      expect(result.savings['A'], equals(35.0));
      expect(result.savings['B'], equals(35.0));
    });

    test('Rejects pooling if any passenger detour exceeds 15%', () {
      const allocator = FareAllocator();

      final candidates = [
        const BookingCandidate(id: 'A', partySize: 1, soloKm: 8.0, sharedKm: 8.5), // 6.25% detour
        const BookingCandidate(id: 'B', partySize: 1, soloKm: 10.0, sharedKm: 11.8), // 18% detour (violates 15%)
      ];

      final result = allocator.allocate(
        candidates: candidates,
        totalSharedKm: 14.0,
        coalitionDistancesKm: {'A,B': 14.0},
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('exceeds the 15% maximum guarantee'));
      expect(result.rejectionReason, contains('rider B'));
    });
  });
}
