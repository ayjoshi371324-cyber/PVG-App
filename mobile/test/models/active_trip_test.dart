import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

void main() {
  group('TripWaypoint', () {
    test('creates waypoint with proper attributes and status', () {
      const waypoint = TripWaypoint(
        id: 'wp-01',
        location: PuneLandmarks.kothrud,
        passengerName: 'You',
        isUser: true,
        type: WaypointType.pickup,
        status: WaypointStatus.current,
        estimatedMinutes: 3,
      );

      expect(waypoint.id, equals('wp-01'));
      expect(waypoint.isUser, isTrue);
      expect(waypoint.type, equals(WaypointType.pickup));
      expect(waypoint.status, equals(WaypointStatus.current));
      expect(waypoint.label, equals('Pickup You at Kothrud Stand'));
    });

    test('copyWith updates waypoint status', () {
      const waypoint = TripWaypoint(
        id: 'wp-02',
        location: PuneLandmarks.swargate,
        passengerName: 'Priya',
        type: WaypointType.pickup,
        status: WaypointStatus.pending,
        estimatedMinutes: 8,
      );

      final updated = waypoint.copyWith(status: WaypointStatus.completed);
      expect(updated.status, equals(WaypointStatus.completed));
    });
  });

  group('MidTripJoinRequest', () {
    test('accepts valid mid-trip join when detour remains <= 15.0%', () {
      final joinReq = MidTripJoinRequest(
        requestId: 'join-001',
        passengerName: 'Vikram S.',
        pickupLocation: PuneLandmarks.shivajiNagar,
        dropoffLocation: PuneLandmarks.hinjawadiPhase1,
        previousDetourPercentage: 8.4,
        newDetourPercentage: 11.6,
        additionalSavings: 25.0,
        newSharedFare: 171.0,
      );

      expect(joinReq.isDetourGuaranteed, isTrue);
      expect(joinReq.detourDelta, closeTo(3.2, 0.001));
    });

    test('strictly rejects mid-trip join request if new detour exceeds 15.0%', () {
      expect(
        () => MidTripJoinRequest(
          requestId: 'join-illegal',
          passengerName: 'Sanjay T.',
          pickupLocation: PuneLandmarks.hadapsar,
          dropoffLocation: PuneLandmarks.vimanNagar,
          previousDetourPercentage: 8.4,
          newDetourPercentage: 16.2,
          additionalSavings: 15.0,
          newSharedFare: 181.0,
        ),
        throwsA(isA<DetourGuaranteeViolationException>()),
      );
    });
  });

  group('ActiveTrip', () {
    late PooledRideOffer sampleOffer;

    setUp(() {
      sampleOffer = PooledRideOffer(
        offerId: 'offer-1',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 8.4,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 196.0,
          coalitionSize: 3,
        ),
      );
    });

    test('initializes with assigned offer and waypoints', () {
      final trip = ActiveTrip.fromOffer(
        offer: sampleOffer,
        vehiclePosition: const LatLng(18.5074, 73.8077),
      );

      expect(trip.waypoints.length, greaterThanOrEqualTo(2));
      expect(trip.currentWaypointIndex, equals(0));
      expect(trip.currentDetourPercentage, equals(8.4));
      expect(trip.isCompleted, isFalse);
    });

    test('advances waypoint step and calculates progress', () {
      final trip = ActiveTrip.fromOffer(
        offer: sampleOffer,
        vehiclePosition: const LatLng(18.5074, 73.8077),
      );

      final nextTrip = trip.advanceWaypoint();
      expect(nextTrip.currentWaypointIndex, equals(1));
      expect(nextTrip.waypoints[0].status, equals(WaypointStatus.completed));
      expect(nextTrip.progress, greaterThan(0.0));
    });

    test('applies approved mid-trip join request inserting intermediate stop', () {
      final trip = ActiveTrip.fromOffer(
        offer: sampleOffer,
        vehiclePosition: const LatLng(18.5074, 73.8077),
      );

      final joinReq = MidTripJoinRequest(
        requestId: 'join-001',
        passengerName: 'Vikram S.',
        pickupLocation: PuneLandmarks.shivajiNagar,
        dropoffLocation: PuneLandmarks.hinjawadiPhase1,
        previousDetourPercentage: 8.4,
        newDetourPercentage: 11.6,
        additionalSavings: 25.0,
        newSharedFare: 171.0,
      );

      final modifiedTrip = trip.applyMidTripJoin(joinReq);
      expect(modifiedTrip.currentDetourPercentage, equals(11.6));
      expect(
        modifiedTrip.waypoints.any((w) => w.passengerName == 'Vikram S.'),
        isTrue,
      );
    });
  });
}
