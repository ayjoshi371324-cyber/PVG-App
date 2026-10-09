import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/live_trip_tracking_card.dart';
import 'package:ridepool_app/widgets/mid_trip_consent_sheet.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/trip_progression_bar.dart';

void main() {
  group('TripProgressionBar', () {
    testWidgets('renders all milestone waypoints with proper status icons', (tester) async {
      const waypoints = [
        TripWaypoint(
          id: 'w1',
          location: PuneLandmarks.kothrud,
          passengerName: 'You',
          isUser: true,
          type: WaypointType.pickup,
          status: WaypointStatus.completed,
          estimatedMinutes: 0,
        ),
        TripWaypoint(
          id: 'w2',
          location: PuneLandmarks.swargate,
          passengerName: 'Priya',
          type: WaypointType.pickup,
          status: WaypointStatus.current,
          estimatedMinutes: 6,
        ),
        TripWaypoint(
          id: 'w3',
          location: PuneLandmarks.hinjawadiPhase1,
          passengerName: 'You',
          isUser: true,
          type: WaypointType.dropoff,
          status: WaypointStatus.pending,
          estimatedMinutes: 24,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: TripProgressionBar(waypoints: waypoints),
            ),
          ),
        ),
      );

      expect(find.textContaining('Pickup You at Kothrud Stand'), findsOneWidget);
      expect(find.textContaining('Pickup Priya at Swargate'), findsOneWidget);
      expect(find.textContaining('Drop off You at Hinjawadi Phase 1'), findsOneWidget);

      // Verify status indicators
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('NEXT STOP'), findsOneWidget);
    });
  });

  group('MidTripConsentSheet', () {
    testWidgets('renders new rider details, detour guarantee, and triggers consent actions', (tester) async {
      bool approved = false;
      bool rejected = false;

      final joinReq = MidTripJoinRequest(
        requestId: 'join-42',
        passengerName: 'Vikram S.',
        pickupLocation: PuneLandmarks.shivajiNagar,
        dropoffLocation: PuneLandmarks.hinjawadiPhase1,
        previousDetourPercentage: 8.4,
        newDetourPercentage: 11.5,
        additionalSavings: 25.0,
        newSharedFare: 171.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: MidTripConsentSheet(
              joinRequest: joinReq,
              onApprove: () => approved = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      // Verify header and passenger info
      expect(find.text('Mid-Trip Join Request'), findsOneWidget);
      expect(find.textContaining('Vikram S.'), findsOneWidget);
      expect(find.textContaining('Shivaji Nagar'), findsOneWidget);

      // Verify <= 15% guarantee badge
      expect(find.text('+11.5% Detour'), findsOneWidget);
      expect(find.text('≤ 15% Guaranteed'), findsOneWidget);

      // Verify additional savings
      expect(find.textContaining('₹25'), findsOneWidget);

      // Tap Reject
      final rejectBtn = find.byKey(const Key('reject_mid_trip_join_button'));
      expect(rejectBtn, findsOneWidget);
      await tester.tap(rejectBtn);
      await tester.pump();
      expect(rejected, isTrue);

      // Tap Approve
      final approveBtn = find.byKey(const Key('approve_mid_trip_join_button'));
      expect(approveBtn, findsOneWidget);
      await tester.tap(approveBtn);
      await tester.pump();
      expect(approved, isTrue);
    });
  });

  group('LiveTripTrackingCard', () {
    late ActiveTrip sampleTrip;

    setUp(() {
      final offer = PooledRideOffer(
        offerId: 'offer-active',
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

      sampleTrip = ActiveTrip.fromOffer(
        offer: offer,
        vehiclePosition: const LatLng(18.5074, 73.8077),
      );
    });

    testWidgets('renders vehicle info, progression bar, and triggers advance step', (tester) async {
      bool stepAdvanced = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LiveTripTrackingCard(
                trip: sampleTrip,
                onAdvanceStep: () => stepAdvanced = true,
                onSimulateJoin: () {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tata Tigor EV'), findsOneWidget);
      expect(find.text('MH-12-RN-4821'), findsOneWidget);
      expect(find.byType(TripProgressionBar), findsOneWidget);

      final advanceBtn = find.byKey(const Key('advance_trip_step_button'));
      expect(advanceBtn, findsOneWidget);
      await tester.tap(advanceBtn);
      await tester.pump();
      expect(stepAdvanced, isTrue);
    });
  });

  group('PuneMapWidget with vehicle marker', () {
    testWidgets('renders vehicle marker when vehiclePosition is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PuneMapWidget(
              pickup: PuneLandmarks.kothrud,
              dropoff: PuneLandmarks.hinjawadiPhase1,
              vehiclePosition: LatLng(18.5074, 73.8077),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('vehicle_marker_icon')), findsOneWidget);
    });
  });
}
