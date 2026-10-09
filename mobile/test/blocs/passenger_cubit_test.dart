import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

void main() {
  group('PassengerCubit', () {
    late PassengerCubit cubit;

    setUp(() {
      cubit = PassengerCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default preset pickup and dropoff with route estimate', () {
      expect(cubit.state.pickup, isNotNull);
      expect(cubit.state.dropoff, isNotNull);
      expect(cubit.state.estimate, isNotNull);
      expect(cubit.state.estimate!.distanceKm, greaterThan(0));
      expect(cubit.state.status, equals(PassengerBookingStatus.planning));
      expect(cubit.state.partySize, equals(1));
      expect(cubit.state.countdownSeconds, equals(15));
    });

    test('setPickup recalculates route estimate', () {
      final initialDropoff = cubit.state.dropoff;
      cubit.setPickup(PuneLandmarks.koregaonPark);

      expect(cubit.state.pickup, equals(PuneLandmarks.koregaonPark));
      expect(cubit.state.dropoff, equals(initialDropoff));
      expect(cubit.state.estimate!.pickup, equals(PuneLandmarks.koregaonPark));
    });

    test('setDropoff recalculates route estimate', () {
      cubit.setDropoff(PuneLandmarks.swargate);

      expect(cubit.state.dropoff, equals(PuneLandmarks.swargate));
      expect(cubit.state.estimate!.dropoff, equals(PuneLandmarks.swargate));
    });

    test('swapLocations switches pickup and dropoff and recalculates', () {
      final oldPickup = cubit.state.pickup;
      final oldDropoff = cubit.state.dropoff;

      cubit.swapLocations();

      expect(cubit.state.pickup, equals(oldDropoff));
      expect(cubit.state.dropoff, equals(oldPickup));
      expect(cubit.state.estimate!.pickup, equals(oldDropoff));
      expect(cubit.state.estimate!.dropoff, equals(oldPickup));
    });

    test('party size validates within capacity 1 to 3', () {
      expect(cubit.state.partySize, equals(1));

      cubit.incrementPartySize();
      expect(cubit.state.partySize, equals(2));

      cubit.incrementPartySize();
      expect(cubit.state.partySize, equals(3));

      // Attempt to exceed 3 seats is ignored / clamped
      cubit.incrementPartySize();
      expect(cubit.state.partySize, equals(3));

      cubit.decrementPartySize();
      expect(cubit.state.partySize, equals(2));

      cubit.decrementPartySize();
      expect(cubit.state.partySize, equals(1));

      // Attempt to decrease below 1 seat is ignored / clamped
      cubit.decrementPartySize();
      expect(cubit.state.partySize, equals(1));

      cubit.setPartySize(3);
      expect(cubit.state.partySize, equals(3));

      cubit.setPartySize(5); // Out of bounds
      expect(cubit.state.partySize, equals(3));
    });

    test('startBatchWaiting enters batchWaiting state and ticks down', () async {
      cubit.startBatchWaiting(durationSeconds: 2);
      expect(cubit.state.status, equals(PassengerBookingStatus.batchWaiting));
      expect(cubit.state.countdownSeconds, equals(2));

      // Wait 1.1s for tick
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(cubit.state.countdownSeconds, equals(1));

      // Wait another 1.1s for completion
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(cubit.state.status, equals(PassengerBookingStatus.offerReceived));
      expect(cubit.state.countdownSeconds, equals(0));
    });

    test('cancelBatchWaiting cancels timer and reverts to planning state', () async {
      cubit.startBatchWaiting(durationSeconds: 15);
      expect(cubit.state.status, equals(PassengerBookingStatus.batchWaiting));

      cubit.cancelBatchWaiting();
      expect(cubit.state.status, equals(PassengerBookingStatus.planning));
      expect(cubit.state.countdownSeconds, equals(15));
    });

    test('receiveOffer populates activeOffer and starts offer expiry countdown', () async {
      final validOffer = PooledRideOffer(
        offerId: 'offer-101',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 9.2,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 196.0,
          coalitionSize: 3,
        ),
        offerExpirySeconds: 3,
      );

      cubit.receiveOffer(validOffer);

      expect(cubit.state.status, equals(PassengerBookingStatus.offerReceived));
      expect(cubit.state.activeOffer, equals(validOffer));
      expect(cubit.state.offerExpirySeconds, equals(3));

      // Wait 1.1s for tick
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(cubit.state.offerExpirySeconds, equals(2));
    });

    test('receiveOffer throws DetourGuaranteeViolationException if detour exceeds 15.0%', () {
      expect(
        () => cubit.receiveOffer(
          PooledRideOffer(
            offerId: 'offer-invalid',
            vehicleModel: 'Tata Tigor EV',
            licensePlate: 'MH-12-RN-4821',
            driverName: 'Suresh K.',
            driverRating: 4.9,
            pickup: PuneLandmarks.kothrud,
            dropoff: PuneLandmarks.hinjawadiPhase1,
            pickupEtaMinutes: 4,
            dropoffEtaMinutes: 35,
            coPassengersCount: 2,
            detourPercentage: 18.0,
            fareBreakdown: ShapleyFareBreakdown(
              soloFare: 280.0,
              sharedFare: 196.0,
              coalitionSize: 3,
            ),
          ),
        ),
        throwsA(isA<DetourGuaranteeViolationException>()),
      );
    });

    test('acceptOffer transitions to tripActive and cancels expiry timer', () {
      final validOffer = PooledRideOffer(
        offerId: 'offer-102',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 8.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 195.0,
          coalitionSize: 3,
        ),
      );

      cubit.receiveOffer(validOffer);
      cubit.acceptOffer();

      expect(cubit.state.status, equals(PassengerBookingStatus.tripActive));
      expect(cubit.state.activeOffer, equals(validOffer));
    });

    test('declineOffer cancels expiry timer and reverts to planning', () {
      final validOffer = PooledRideOffer(
        offerId: 'offer-103',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 8.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 195.0,
          coalitionSize: 3,
        ),
      );

      cubit.receiveOffer(validOffer);
      cubit.declineOffer();

      expect(cubit.state.status, equals(PassengerBookingStatus.planning));
      expect(cubit.state.activeOffer, isNull);
    });

    test('offer expiry timer reaches 0 and automatically reverts to planning', () async {
      final shortOffer = PooledRideOffer(
        offerId: 'offer-104',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 7.5,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 195.0,
          coalitionSize: 3,
        ),
        offerExpirySeconds: 1,
      );

      cubit.receiveOffer(shortOffer);
      expect(cubit.state.status, equals(PassengerBookingStatus.offerReceived));

      await Future.delayed(const Duration(milliseconds: 1200));

      expect(cubit.state.status, equals(PassengerBookingStatus.planning));
      expect(cubit.state.activeOffer, isNull);
    });
  });
}
