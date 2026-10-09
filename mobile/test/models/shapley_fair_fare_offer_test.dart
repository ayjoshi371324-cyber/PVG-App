import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

void main() {
  group('ShapleyFareBreakdown & PooledRideOffer Models', () {
    test('computes exact per-person fare for parties and verifies detour ceiling', () {
      final breakdown = ShapleyFareBreakdown(
        soloFare: 180.0,
        sharedFare: 120.0,
        coalitionSize: 2,
        partySize: 2,
        totalTripCost: 260.0,
        fixedFeeShare: 10.0,
        marginalContribution: 120.0,
        marginalContributions: const {
          'Rider A (You)': 120.0,
          'Rider B': 140.0,
        },
        coalitionTable: const {
          'Rider A (You)': 180.0,
          'Rider B': 200.0,
          'Rider A (You), Rider B': 260.0,
        },
        passengerShares: const {
          'Rider A (You)': 120.0,
          'Rider B': 140.0,
        },
        partySizes: const {
          'Rider A (You)': 2,
          'Rider B': 1,
        },
      );

      // Verifications
      expect(breakdown.soloFare, equals(180.0));
      expect(breakdown.sharedFare, equals(120.0));
      expect(breakdown.savings, equals(60.0));
      expect(breakdown.partySize, equals(2));
      expect(breakdown.perPersonFare, equals(60.0)); // 120 / 2
      expect(breakdown.totalTripCost, equals(260.0));
      expect(breakdown.fixedFeeShare, equals(10.0));

      // Sum of all passenger shares matches totalTripCost exactly
      final sumShares = breakdown.passengerShares.values.fold(0.0, (s, v) => s + v);
      expect(sumShares, equals(breakdown.totalTripCost));
    });

    test('throws DetourGuaranteeViolationException when detour exceeds 15.0%', () {
      expect(
        () => PooledRideOffer(
          offerId: 'offer-invalid-detour',
          vehicleModel: 'Maruti Ertiga',
          licensePlate: 'MH-12-RP-1001',
          driverName: 'Sanjay M.',
          driverRating: 4.8,
          pickup: PuneLandmarks.kothrud,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          pickupEtaMinutes: 4,
          dropoffEtaMinutes: 28,
          coPassengersCount: 2,
          detourPercentage: 15.8, // strictly > 15.0%
          fareBreakdown: ShapleyFareBreakdown(
            soloFare: 100.0,
            sharedFare: 70.0,
            coalitionSize: 2,
          ),
        ),
        throwsA(isA<DetourGuaranteeViolationException>()),
      );
    });

    test('TripWaypoint supports multi-passenger booking attributes and marker codes', () {
      const wpPickup = TripWaypoint(
        id: 'wp-p1',
        location: PuneLandmarks.kothrud,
        passengerName: 'You',
        isUser: true,
        type: WaypointType.pickup,
        status: WaypointStatus.current,
        estimatedMinutes: 5,
        bookingId: 'book-1',
        bookingIndex: 1,
        passengerAlias: 'Rider A (You)',
        partySize: 2,
        stopSequence: 1,
        markerCode: 'P1',
        bookingColor: BookingColors.booking1,
      );

      expect(wpPickup.markerCode, equals('P1'));
      expect(wpPickup.bookingIndex, equals(1));
      expect(wpPickup.partySize, equals(2));
      expect(wpPickup.passengerAlias, equals('Rider A (You)'));
      expect(wpPickup.bookingColor, equals(BookingColors.booking1));

      const wpDropoff = TripWaypoint(
        id: 'wp-d1',
        location: PuneLandmarks.hinjawadiPhase1,
        passengerName: 'You',
        isUser: true,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: 30,
        bookingId: 'book-1',
        bookingIndex: 1,
        passengerAlias: 'Rider A (You)',
        partySize: 2,
        stopSequence: 3,
        markerCode: 'D1',
        bookingColor: BookingColors.booking1,
      );

      expect(wpDropoff.markerCode, equals('D1'));
      expect(wpDropoff.stopSequence, equals(3));
    });
  });
}
