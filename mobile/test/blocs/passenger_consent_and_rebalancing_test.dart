import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PassengerCubit - Dynamic Consent & Rebalancing (Seam 4)', () {
    late PassengerCubit cubit;
    late PooledRideOffer initialOffer;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = PassengerCubit();

      initialOffer = PooledRideOffer(
        offerId: 'offer-consent-1',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes: 24,
        coPassengersCount: 1,
        coPassengerLabels: const ['Priya'],
        detourPercentage: 5.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 200.0,
          sharedFare: 145.0,
          coalitionSize: 2,
        ),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initiates mid-trip join consent with 30s countdown and auto-rollbacks on timeout', () async {
      cubit.receiveOffer(initialOffer);
      cubit.acceptOffer();
      expect(cubit.state.status, equals(PassengerBookingStatus.tripActive));

      final joinReq = MidTripJoinRequest(
        requestId: 'join-timeout-1',
        passengerName: 'Vikram S.',
        pickupLocation: PuneLandmarks.shivajiNagar,
        dropoffLocation: PuneLandmarks.hinjawadiPhase1,
        previousDetourPercentage: 5.0,
        newDetourPercentage: 9.2,
        additionalSavings: 25.0,
        newSharedFare: 120.0,
        etaDeltaMinutes: 3,
        updatedEtaMinutes: 27,
        secondsRemaining: 30,
      );

      cubit.requestMidTripJoin(joinReq);

      expect(cubit.state.activeTrip?.pendingJoinRequest, isNotNull);
      expect(cubit.state.consentCountdownSeconds, equals(30));

      // Simulate timeout
      cubit.simulateConsentTimeout();

      // Cleanly rolls back without altering active trip
      expect(cubit.state.activeTrip?.pendingJoinRequest, isNull);
      expect(cubit.state.activeTrip?.currentDetourPercentage, equals(5.0));
      expect(
        cubit.state.activeTrip?.waypoints.any((w) => w.passengerName == 'Vikram S.'),
        isFalse,
      );
    });

    test('rejection cleanly rolls back proposed route without modifying trip waypoints', () {
      cubit.receiveOffer(initialOffer);
      cubit.acceptOffer();

      final initialWaypointCount = cubit.state.activeTrip!.waypoints.length;

      final joinReq = MidTripJoinRequest(
        requestId: 'join-reject-1',
        passengerName: 'Vikram S.',
        pickupLocation: PuneLandmarks.shivajiNagar,
        dropoffLocation: PuneLandmarks.hinjawadiPhase1,
        previousDetourPercentage: 5.0,
        newDetourPercentage: 9.2,
        additionalSavings: 25.0,
        newSharedFare: 120.0,
        etaDeltaMinutes: 3,
        updatedEtaMinutes: 27,
      );

      cubit.requestMidTripJoin(joinReq);
      cubit.rejectMidTripJoin();

      expect(cubit.state.activeTrip?.pendingJoinRequest, isNull);
      expect(cubit.state.activeTrip?.waypoints.length, equals(initialWaypointCount));
      expect(cubit.state.activeTrip?.currentDetourPercentage, equals(5.0));
    });

    test('pre-departure cancellation removes passenger and resets route to planning or rebalances', () {
      cubit.receiveOffer(initialOffer);
      cubit.acceptOffer();

      // Rider cancels trip before departing
      cubit.cancelActiveTripPreDeparture();

      expect(cubit.state.status, equals(PassengerBookingStatus.planning));
      expect(cubit.state.activeTrip, isNull);
    });

    test('mid-trip co-passenger cancellation freezes completed prefixes and re-optimizes pending leg', () {
      cubit.receiveOffer(initialOffer);
      cubit.acceptOffer();

      // Advance one stop (completed prefix)
      cubit.advanceTripStep();
      expect(cubit.state.activeTrip!.currentWaypointIndex, equals(1));
      expect(cubit.state.activeTrip!.waypoints[0].status, equals(WaypointStatus.completed));

      // Co-passenger cancels mid-trip
      cubit.cancelCoPassengerMidTrip(bookingId: 'book-2', partySize: 1);

      final trip = cubit.state.activeTrip!;
      // Prefix remains frozen completed
      expect(trip.waypoints[0].status, equals(WaypointStatus.completed));
      // Co-passenger waypoints removed from remaining leg
      expect(trip.waypoints.any((w) => w.bookingId == 'book-2'), isFalse);
    });
  });
}
