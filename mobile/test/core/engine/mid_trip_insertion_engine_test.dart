import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/mid_trip_insertion_engine.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

void main() {
  group('MidTripInsertionEngine - TDD Seam 1', () {
    late MidTripInsertionEngine engine;

    setUp(() {
      engine = MidTripInsertionEngine(
        estimator: const RouteEstimatorService(),
      );
    });

    test('strictly rejects candidate insertion if segment seat capacity is exceeded', () {
      // Vehicle capacity: 4. Currently 3 passengers onboard, heading to Hinjawadi.
      // Candidate requests 2 seats (3 + 2 = 5 > 4).
      final result = engine.evaluate(
        currentLocation: PuneLandmarks.kothrud,
        vehicleCapacity: 4,
        currentOnboardPassengers: [
          const InFlightPassenger(
            bookingId: 'book-1',
            passengerName: 'Aakash',
            soloDistanceKm: 14.0,
            currentFare: 280.0,
            partySize: 3,
            dropoff: PuneLandmarks.hinjawadiPhase1,
            estimatedEtaMinutes: 25,
          ),
        ],
        candidate: const CandidateJoinRequest(
          bookingId: 'book-join-1',
          passengerName: 'Vikram',
          pickup: PuneLandmarks.shivajiNagar,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          partySize: 2,
        ),
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('Capacity exceeded'));
      expect(result.proposal, isNull);
    });

    test('strictly rejects candidate insertion if detour exceeds 15% limit for existing rider', () {
      // Existing rider travelling from Kothrud to Bavdhan (direct ~4.5 km).
      // Candidate wants to be picked up in Hadapsar (opposite side of Pune, massive detour > 15%).
      final result = engine.evaluate(
        currentLocation: PuneLandmarks.kothrud,
        vehicleCapacity: 4,
        currentOnboardPassengers: [
          const InFlightPassenger(
            bookingId: 'book-1',
            passengerName: 'Rohan',
            soloDistanceKm: 4.5,
            currentFare: 90.0,
            partySize: 1,
            dropoff: PuneLocation(
              name: 'Bavdhan Flyover',
              latitude: 18.5126,
              longitude: 73.7712,
            ),
            estimatedEtaMinutes: 10,
          ),
        ],
        candidate: const CandidateJoinRequest(
          bookingId: 'book-join-hadapsar',
          passengerName: 'Sanjay',
          pickup: PuneLandmarks.hadapsar, // Huge eastern detour
          dropoff: PuneLandmarks.vimanNagar,
          partySize: 1,
        ),
      );

      expect(result.isFeasible, isFalse);
      expect(result.rejectionReason, contains('Detour'));
      expect(result.proposal, isNull);
    });

    test('accepts valid insertion along corridor with <=15% detour and generates Shapley deltas', () {
      // Existing rider travelling from Kothrud to Hinjawadi Phase 1.
      // Vehicle is at Kothrud.
      // Candidate asks to join along the corridor at Bavdhan to Hinjawadi Phase 1.
      // Both stay well within 15% detour limit and capacity (1 + 1 = 2 <= 4).
      const bavdhan = PuneLocation(
        name: 'Bavdhan Flyover',
        latitude: 18.5126,
        longitude: 73.7712,
      );
      final soloAakash = const RouteEstimatorService().estimateRoute(
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
      );

      final result = engine.evaluate(
        currentLocation: PuneLandmarks.kothrud,
        vehicleCapacity: 4,
        currentOnboardPassengers: [
          InFlightPassenger(
            bookingId: 'book-1',
            passengerName: 'Aakash',
            soloDistanceKm: soloAakash.distanceKm,
            currentFare: soloAakash.referenceFare,
            partySize: 1,
            dropoff: PuneLandmarks.hinjawadiPhase1,
            estimatedEtaMinutes: 25,
          ),
        ],
        candidate: const CandidateJoinRequest(
          bookingId: 'book-join-vikram',
          passengerName: 'Vikram',
          pickup: bavdhan,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          partySize: 1,
        ),
      );

      expect(result.isFeasible, isTrue);
      expect(result.rejectionReason, isNull);
      expect(result.proposal, isNotNull);

      final proposal = result.proposal!;
      expect(proposal.candidateName, equals('Vikram'));
      expect(proposal.newDetourPercentage, lessThanOrEqualTo(15.0));
      expect(proposal.existingRiderDeltas.containsKey('book-1'), isTrue);

      final riderDelta = proposal.existingRiderDeltas['book-1']!;
      // Fare decreases (discount) with additional co-passenger via Shapley
      expect(riderDelta.updatedFare, lessThan(soloAakash.referenceFare));
      expect(riderDelta.fareSavingsDelta, greaterThan(0.0));
      // Explicit delta values provided
      expect(riderDelta.etaDeltaMinutes, isNotNull);
      expect(riderDelta.detourDeltaPercentage, isNotNull);
    });
  });
}
