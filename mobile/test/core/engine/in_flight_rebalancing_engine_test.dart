import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/in_flight_rebalancing_engine.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

void main() {
  group('InFlightRebalancingEngine - TDD Seam 3', () {
    late InFlightRebalancingEngine rebalancer;
    late SeatLedger ledgerWithTwoRiders;
    late ActiveTrip initialMultiTrip;

    setUp(() {
      rebalancer = const InFlightRebalancingEngine(
        estimator: RouteEstimatorService(),
      );

      // Ledger with Rider A (book-1, 1 seat) and Rider B (book-2, 1 seat)
      ledgerWithTwoRiders = SeatLedger.empty(capacity: 4)
          .holdSeats(bookingId: 'book-1', partySize: 1)
          .confirmSeats(bookingId: 'book-1', partySize: 1)
          .holdSeats(bookingId: 'book-2', partySize: 1)
          .confirmSeats(bookingId: 'book-2', partySize: 1);

      const bavdhan = PuneLocation(
        name: 'Bavdhan Flyover',
        latitude: 18.5126,
        longitude: 73.7712,
      );

      // Pooled offer with 2 passengers
      final offer = PooledRideOffer(
        offerId: 'offer-multi-1',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes: 24,
        coPassengersCount: 1,
        coPassengerLabels: const ['Priya (Bavdhan)'],
        detourPercentage: 5.5,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 200.0,
          sharedFare: 145.0,
          coalitionSize: 2,
        ),
      );

      final waypoints = [
        const TripWaypoint(
          id: 'w-p1',
          location: PuneLandmarks.kothrud,
          passengerName: 'You',
          isUser: true,
          type: WaypointType.pickup,
          status: WaypointStatus.current,
          estimatedMinutes: 3,
          bookingId: 'book-1',
          stopSequence: 1,
        ),
        const TripWaypoint(
          id: 'w-p2',
          location: bavdhan,
          passengerName: 'Priya',
          type: WaypointType.pickup,
          status: WaypointStatus.pending,
          estimatedMinutes: 8,
          bookingId: 'book-2',
          stopSequence: 2,
        ),
        const TripWaypoint(
          id: 'w-d1',
          location: PuneLandmarks.hinjawadiPhase1,
          passengerName: 'You',
          isUser: true,
          type: WaypointType.dropoff,
          status: WaypointStatus.pending,
          estimatedMinutes: 24,
          bookingId: 'book-1',
          stopSequence: 3,
        ),
        const TripWaypoint(
          id: 'w-d2',
          location: PuneLandmarks.hinjawadiPhase1,
          passengerName: 'Priya',
          type: WaypointType.dropoff,
          status: WaypointStatus.pending,
          estimatedMinutes: 26,
          bookingId: 'book-2',
          stopSequence: 4,
        ),
      ];

      initialMultiTrip = ActiveTrip(
        tripId: 'trip-multi-1',
        offer: offer,
        waypoints: waypoints,
        currentWaypointIndex: 0,
        vehiclePosition: PuneLandmarks.kothrud.toLatLng(),
        currentDetourPercentage: 5.5,
      );
    });

    test('pre-departure cancellation removes passenger, releases ledger seats, and rebalances remaining route and Shapley fares', () {
      // Co-passenger Priya (book-2) cancels before departure
      final result = rebalancer.handlePreDepartureCancellation(
        trip: initialMultiTrip,
        ledger: ledgerWithTwoRiders,
        cancelledBookingId: 'book-2',
        cancelledPartySize: 1,
      );

      // 1. Released seats in ledger
      expect(result.updatedLedger.reserved, equals(1));
      expect(result.updatedLedger.available, equals(3));

      // 2. Remaining waypoints exclude Priya
      expect(
        result.updatedTrip.waypoints.any((w) => w.bookingId == 'book-2'),
        isFalse,
      );
      expect(result.updatedTrip.waypoints.length, equals(2)); // Only P1 and D1

      // 3. Re-calculated fares for remaining solo rider
      expect(result.reallocatedFares['book-1'], equals(200.0)); // Back to solo direct fare
      expect(result.updatedTrip.offer.coPassengersCount, equals(0));
    });

    test('mid-trip cancellation freezes completed prefixes, re-optimizes pending leg, and flags re-consent when cost increases', () {
      // Advance trip: Vehicle picked up Rider A at Kothrud and boarded them
      var tripInFlight = initialMultiTrip.advanceWaypoint(); // index 1 (heading to Bavdhan for Priya)
      var inFlightLedger = ledgerWithTwoRiders.boardSeats(bookingId: 'book-1', partySize: 1);

      expect(tripInFlight.currentWaypointIndex, equals(1));
      expect(tripInFlight.waypoints[0].status, equals(WaypointStatus.completed));

      // Priya cancels while vehicle is on route before her pickup
      final result = rebalancer.handleMidTripCancellation(
        trip: tripInFlight,
        ledger: inFlightLedger,
        cancelledBookingId: 'book-2',
        cancelledPartySize: 1,
      );

      // 1. Completed prefix stop (Kothrud pickup) is FROZEN
      expect(result.updatedTrip.waypoints[0].id, equals('w-p1'));
      expect(result.updatedTrip.waypoints[0].status, equals(WaypointStatus.completed));

      // 2. Pending leg is re-optimized directly to Rider A's dropoff
      expect(result.updatedTrip.waypoints.any((w) => w.bookingId == 'book-2'), isFalse);
      expect(result.updatedTrip.waypoints.length, equals(2)); // P1 (completed) + D1 (pending)

      // 3. Fares adjusted: Cost increases because co-passenger dropped out, requiring re-consent
      expect(result.requiresReConsent, isTrue);
      expect(result.reallocatedFares['book-1'], greaterThan(145.0)); // Increased from 145 shared fare
    });
  });
}
