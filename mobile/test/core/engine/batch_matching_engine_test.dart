import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

void main() {
  group('Combinatorial Batch Matching Engine', () {
    late PuneLocation kothrud;
    late PuneLocation hinjawadi;
    late PuneLocation shivajiNagar;

    late BatchVehicle autoFleet;
    late BatchVehicle carFleet;
    late BatchVehicle carXlFleet;

    setUp(() {
      kothrud = PuneLandmarks.kothrud;
      hinjawadi = PuneLandmarks.hinjawadiPhase1;
      shivajiNagar = PuneLandmarks.shivajiNagar;

      autoFleet = BatchVehicle(
        id: 'v-auto-1',
        model: 'Bajaj RE EV',
        licensePlate: 'MH-12-AU-1001',
        driverName: 'Santosh T.',
        driverRating: 4.85,
        tier: VehicleTier.auto,
        currentLocation: kothrud,
      );

      carFleet = BatchVehicle(
        id: 'v-car-1',
        model: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.90,
        tier: VehicleTier.car,
        currentLocation: kothrud,
      );

      carXlFleet = BatchVehicle(
        id: 'v-carxl-1',
        model: 'Toyota Innova Hycross',
        licensePlate: 'MH-12-XL-9009',
        driverName: 'Mahesh P.',
        driverRating: 4.95,
        tier: VehicleTier.carXl,
        currentLocation: kothrud,
      );
    });

    test('enforces strict vehicle tier matching: Auto only matches with Auto', () {
      final userRequest = BatchRideRequest(
        id: 'req-user-auto',
        passengerName: 'Naren',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.auto,
      );

      // Only Car and Car XL vehicles are available, no Auto
      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: userRequest,
        queuedRequests: const [],
        availableVehicles: [carFleet, carXlFleet],
      );

      expect(outcome, isA<NoValidMatchOutcome>());
      final noMatch = outcome as NoValidMatchOutcome;
      expect(noMatch.reason, equals(NoMatchReason.tierMismatch));
      expect(noMatch.explanation, contains('Auto'));
    });

    test('enforces vehicle tier boundaries: requests of different tiers are never pooled', () {
      final userAuto = BatchRideRequest(
        id: 'req-user-auto',
        passengerName: 'Naren',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.auto,
      );

      final coPassengerCar = BatchRideRequest(
        id: 'req-copassenger-car',
        passengerName: 'Amit',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.car, // Car tier, not Auto!
      );

      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: userAuto,
        queuedRequests: [coPassengerCar],
        availableVehicles: [autoFleet],
      );

      // Co-passenger is Car, so cannot be pooled in Auto. Outcome is SoloDirectRide or NoValidMatch
      expect(outcome, isA<SoloDirectRideOutcome>());
      final solo = outcome as SoloDirectRideOutcome;
      expect(solo.vehicle.tier, equals(VehicleTier.auto));
    });

    test('rejects request when party size exceeds vehicle tier capacity', () {
      final largePartyAuto = BatchRideRequest(
        id: 'req-large',
        passengerName: 'Rohan',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 4, // Auto capacity is only 3
        tier: VehicleTier.auto,
      );

      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: largePartyAuto,
        queuedRequests: const [],
        availableVehicles: [autoFleet],
      );

      expect(outcome, isA<NoValidMatchOutcome>());
      final noMatch = outcome as NoValidMatchOutcome;
      expect(noMatch.reason, equals(NoMatchReason.capacityExceeded));
      expect(noMatch.explanation, contains('exceeds'));
    });

    test('successfully pools compatible requests of the same tier within <= 15% detour', () {
      final user = BatchRideRequest(
        id: 'req-user',
        passengerName: 'Naren',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.car,
      );

      // Compatible co-passenger along west corridor (Bavdhan to Hinjawadi)
      const bavdhan = PuneLocation(
        name: 'Bavdhan Flyover',
        latitude: 18.5126,
        longitude: 73.7712,
      );
      final coPassenger = BatchRideRequest(
        id: 'req-copassenger',
        passengerName: 'Priya',
        pickup: bavdhan,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.car,
      );

      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: user,
        queuedRequests: [coPassenger],
        availableVehicles: [carFleet],
      );

      expect(outcome, isA<MatchFoundOutcome>());
      final match = outcome as MatchFoundOutcome;
      expect(match.vehicle.tier, equals(VehicleTier.car));
      expect(match.matchedRequests.length, equals(2));
      expect(match.detourPercentage, lessThanOrEqualTo(15.0));
      expect(match.offer.isDetourGuaranteed, isTrue);
      expect(match.offer.fareBreakdown.sharedFare,
          lessThanOrEqualTo(match.offer.fareBreakdown.soloFare));
    });

    test('rejects pooled coalition when detour exceeds 15% guarantee', () {
      final user = BatchRideRequest(
        id: 'req-user',
        passengerName: 'Naren',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.car,
      );

      // Co-passenger from central Pune requiring ~31% circuitous detour for user
      final detourPassenger = BatchRideRequest(
        id: 'req-detour',
        passengerName: 'Central Commuter',
        pickup: shivajiNagar,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.car,
      );

      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: user,
        queuedRequests: [detourPassenger],
        availableVehicles: [carFleet],
        allowSoloFallback: false,
      );

      expect(outcome, isA<NoValidMatchOutcome>());
      final noMatch = outcome as NoValidMatchOutcome;
      expect(noMatch.reason, equals(NoMatchReason.detourExceeded));
      expect(noMatch.explanation, contains('15%'));
    });

    test('creates SoloDirectRideOutcome when no pool is available and solo fallback enabled', () {
      final user = BatchRideRequest(
        id: 'req-user',
        passengerName: 'Naren',
        pickup: kothrud,
        dropoff: hinjawadi,
        partySize: 1,
        tier: VehicleTier.carXl,
      );

      final matcher = CombinatorialBatchMatcher();
      final outcome = matcher.match(
        targetRequest: user,
        queuedRequests: const [], // No other riders in batch
        availableVehicles: [carXlFleet],
        allowSoloFallback: true,
      );

      expect(outcome, isA<SoloDirectRideOutcome>());
      final solo = outcome as SoloDirectRideOutcome;
      expect(solo.vehicle.tier, equals(VehicleTier.carXl));
      expect(solo.soloFare, equals(VehicleTier.carXl.calculateEstimatedFare(solo.distanceKm)));
    });
  });

  group('RollingBatchIntakeQueue', () {
    test('validates configurable window between 15 and 90 seconds', () {
      expect(
        () => RollingBatchIntakeQueue(windowSeconds: 10),
        throwsArgumentError,
      );
      expect(
        () => RollingBatchIntakeQueue(windowSeconds: 100),
        throwsArgumentError,
      );

      final validQueue15 = RollingBatchIntakeQueue(windowSeconds: 15);
      expect(validQueue15.windowSeconds, equals(15));

      final validQueue90 = RollingBatchIntakeQueue(windowSeconds: 90);
      expect(validQueue90.windowSeconds, equals(90));
    });

    test('enqueues incoming requests and drains batch on trigger', () {
      final queue = RollingBatchIntakeQueue(windowSeconds: 30);
      final req1 = BatchRideRequest(
        id: 'r1',
        passengerName: 'User 1',
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        tier: VehicleTier.car,
      );
      final req2 = BatchRideRequest(
        id: 'r2',
        passengerName: 'User 2',
        pickup: PuneLandmarks.shivajiNagar,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 2,
        tier: VehicleTier.car,
      );

      queue.enqueue(req1);
      queue.enqueue(req2);
      expect(queue.queuedCount, equals(2));

      final batch = queue.drainBatch();
      expect(batch.length, equals(2));
      expect(queue.queuedCount, equals(0));
    });
  });
}
