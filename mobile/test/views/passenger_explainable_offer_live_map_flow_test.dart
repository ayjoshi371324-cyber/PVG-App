import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/why_am_i_paying_sheet.dart';

void main() {
  group('Ticket 03 - Explainable Shapley Fair-Fare Offer & Multi-Passenger Live Map Integration Flow', () {
    testWidgets('Full flow from explainable Shapley offer review to multi-passenger live tracking',
        (tester) async {
      final cubit = PassengerCubit();

      // Configure initial state with party of 2 and Car XL tier
      cubit.setPickup(PuneLandmarks.kothrud);
      cubit.setDropoff(PuneLandmarks.hinjawadiPhase1);
      cubit.setVehicleTier(VehicleTier.carXl);
      cubit.incrementPartySize(allowTierUpgrade: true); // Party of 2

      await tester.pumpWidget(
        BlocProvider<PassengerCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: UberTheme.lightTheme,
            home: const Scaffold(
              body: PassengerHomeView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Formulate a deterministic pooled offer with co-riders
      final offer = PooledRideOffer(
        offerId: 'offer-flow-003',
        vehicleModel: 'Toyota Innova Crysta',
        licensePlate: 'MH-12-RP-7777',
        driverName: 'Santosh Patil',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes: 24,
        coPassengersCount: 2,
        coPassengerLabels: const ['Rider B (Swargate)', 'Rider C (Shivaji Nagar)'],
        detourPercentage: 9.2, // <= 15.0%
        partySize: 2,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 300.0,
          sharedFare: 200.0,
          coalitionSize: 3,
          partySize: 2,
          perPersonFare: 100.0,
          totalTripCost: 450.0,
          fixedFeeShare: 9.33,
          marginalContribution: 200.0,
          marginalContributions: const {
            'Rider A (You)': 200.0,
            'Rider B': 125.0,
            'Rider C': 125.0,
          },
          coalitionTable: const {
            'Rider A (You)': 300.0,
            'Rider B': 220.0,
            'Rider C': 220.0,
            'Rider A (You), Rider B': 360.0,
            'Rider A (You), Rider C': 360.0,
            'Rider B, Rider C': 320.0,
            'Rider A (You), Rider B, Rider C': 450.0,
          },
          passengerShares: const {
            'Rider A (You)': 200.0,
            'Rider B': 125.0,
            'Rider C': 125.0,
          },
          partySizes: const {
            'Rider A (You)': 2,
            'Rider B': 1,
            'Rider C': 1,
          },
          explanation: 'Exact Shapley fair-fare calculation for Innova Crysta.',
        ),
      );

      final vehicle = BatchVehicle(
        id: 'v-7777',
        model: 'Toyota Innova Crysta',
        licensePlate: 'MH-12-RP-7777',
        driverName: 'Santosh Patil',
        driverRating: 4.9,
        tier: VehicleTier.carXl,
        currentLocation: PuneLandmarks.kothrud,
      );

      final outcome = MatchFoundOutcome(
        vehicle: vehicle,
        matchedRequests: [
          BatchRideRequest(
            id: 'req-target',
            passengerName: 'You',
            pickup: PuneLandmarks.kothrud,
            dropoff: PuneLandmarks.hinjawadiPhase1,
            partySize: 2,
            tier: VehicleTier.carXl,
          ),
          BatchRideRequest(
            id: 'req-b',
            passengerName: 'Priya',
            pickup: PuneLandmarks.swargate,
            dropoff: PuneLandmarks.hinjawadiPhase1,
            partySize: 1,
            tier: VehicleTier.carXl,
          ),
        ],
        totalSharedKm: 28.0,
        detourPercentage: 9.2,
        fareAllocation: const FareAllocationResult(
          isFeasible: true,
          totalTripCost: 450.0,
          soloFares: {'req-target': 300.0, 'req-b': 220.0},
          allocatedFares: {'req-target': 200.0, 'req-b': 125.0, 'req-c': 125.0},
          rawShares: {'req-target': 200.0, 'req-b': 125.0, 'req-c': 125.0},
          perPersonFares: {'req-target': 100.0, 'req-b': 125.0, 'req-c': 125.0},
          savings: {'req-target': 100.0, 'req-b': 95.0},
          detourPercentages: {'req-target': 9.2, 'req-b': 8.0},
          coalitionTable: {'req-target': 300.0},
        ),
        offer: offer,
      );

      // 1. Deliver the match found outcome to the cubit
      cubit.setMatchingOutcome(outcome);
      await tester.pumpAndSettle();

      // Check Offer Card Presentation:
      // Exact Shapley Fare
      expect(find.text('₹200'), findsWidgets);
      // Per-person cost for party of 2
      expect(find.byKey(const Key('per_person_fare_badge')), findsOneWidget);
      expect(find.textContaining('₹100 / person (Party of 2)'), findsOneWidget);
      // Honest Detour <= 15%
      expect(find.text('+9.2% Detour'), findsOneWidget);
      expect(find.text('≤ 15% Guaranteed'), findsOneWidget);
      // Sum of all shares matches total route cost (200 + 125 + 125 = 450)
      expect(find.text('Total: ₹450'), findsOneWidget);
      expect(find.text('₹200.00'), findsOneWidget);
      expect(find.text('₹125.00'), findsNWidgets(2));

      // 2. Open "Why am I paying this fare?" sheet
      final whyButton = find.byKey(const Key('why_am_i_paying_this_fare_button'));
      expect(whyButton, findsOneWidget);
      await tester.ensureVisible(whyButton);
      await tester.tap(whyButton);
      await tester.pumpAndSettle();

      // Verify explanation sheet contents
      expect(find.byType(WhyAmIPayingSheet), findsOneWidget);
      expect(find.byKey(const Key('solo_baseline_fare_row')), findsOneWidget);
      expect(find.byKey(const Key('total_pooled_route_cost_row')), findsOneWidget);
      expect(find.byKey(const Key('marginal_contributions_section')), findsOneWidget);
      expect(find.byKey(const Key('coalition_table_section')), findsOneWidget);
      expect(find.byKey(const Key('exact_sum_match_badge')), findsOneWidget);

      // Dismiss the modal
      Navigator.of(tester.element(find.byType(WhyAmIPayingSheet))).pop();
      await tester.pumpAndSettle();

      // 3. Accept Pooled Ride
      final acceptButton = find.byKey(const Key('accept_pool_offer_button'));
      await tester.ensureVisible(acceptButton);
      await tester.tap(acceptButton);
      await tester.pumpAndSettle();

      // 4. Verify Live Map Multi-Passenger Visualization
      // Numbered markers P1, P2, D1, D2 exist on the live map
      expect(find.byKey(const Key('marker_p1')), findsOneWidget);
      expect(find.byKey(const Key('marker_p2')), findsOneWidget);
      expect(find.byKey(const Key('marker_d1')), findsOneWidget);
      expect(find.byKey(const Key('marker_d2')), findsOneWidget);

      // Route Stop List Legend exists on map
      expect(find.byKey(const Key('map_stop_list_legend')), findsOneWidget);
      expect(find.textContaining('Rider A (You)'), findsWidgets);
      expect(find.textContaining('Rider B'), findsWidgets);
      expect(find.textContaining('Party of 2'), findsWidgets);

      // Confirmed polyline is rendered
      final polyLayer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(polyLayer.polylines.isNotEmpty, isTrue);

      // 5. Simulate mid-trip join proposal -> renders proposed polyline
      final joinButton = find.byKey(const Key('simulate_mid_trip_join_button'));
      await tester.ensureVisible(joinButton);
      await tester.tap(joinButton);
      await tester.pumpAndSettle();

      // Proposed polyline should be in dashed styling
      final polyLayerWithJoin = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      final hasProposedDashed = polyLayerWithJoin.polylines.any(
        (p) => p.pattern != const StrokePattern.solid() && p.color == UberColors.accentGreen,
      );
      expect(hasProposedDashed, isTrue);

      // 6. Complete / approve mid-trip join and advance stop
      cubit.approveMidTripJoin();
      await tester.pumpAndSettle();

      final advanceButton = find.byKey(const Key('advance_trip_step_button'));
      await tester.ensureVisible(advanceButton);
      await tester.tap(advanceButton);
      await tester.pumpAndSettle();

      // Faded completed polyline segment is now present
      final polyLayerAfterAdvance = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      final hasFadedCompleted = polyLayerAfterAdvance.polylines.any(
        (p) => p.color.a < 1.0,
      );
      expect(hasFadedCompleted, isTrue);
    });
  });
}
