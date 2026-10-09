import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/why_am_i_paying_sheet.dart';

void main() {
  group('PooledRideOfferCard Issue 03 Enhancements', () {
    late PooledRideOffer partyOffer;

    setUp(() {
      partyOffer = PooledRideOffer(
        offerId: 'offer-party-001',
        vehicleModel: 'Maruti Ertiga XL',
        licensePlate: 'MH-12-RP-8888',
        driverName: 'Vikram Joshi',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes: 25,
        coPassengersCount: 2,
        coPassengerLabels: const ['Rider B (Swargate)', 'Rider C (Baner)'],
        detourPercentage: 7.5,
        partySize: 2,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 240.0,
          sharedFare: 160.0,
          coalitionSize: 3,
          partySize: 2,
          perPersonFare: 80.0,
          totalTripCost: 380.0,
          fixedFeeShare: 6.67,
          marginalContribution: 160.0,
          marginalContributions: const {
            'Rider A (You)': 160.0,
            'Rider B': 110.0,
            'Rider C': 110.0,
          },
          coalitionTable: const {
            'Rider A (You)': 240.0,
            'Rider B': 180.0,
            'Rider C': 180.0,
            'Rider A (You), Rider B': 300.0,
            'Rider A (You), Rider C': 300.0,
            'Rider B, Rider C': 260.0,
            'Rider A (You), Rider B, Rider C': 380.0,
          },
          passengerShares: const {
            'Rider A (You)': 160.0,
            'Rider B': 110.0,
            'Rider C': 110.0,
          },
          partySizes: const {
            'Rider A (You)': 2,
            'Rider B': 1,
            'Rider C': 1,
          },
          explanation: 'Exact Shapley allocation for Ertiga XL pool.',
        ),
      );
    });

    testWidgets('renders exact Shapley fare, per-person party cost, and honest detour',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PooledRideOfferCard(
                offer: partyOffer,
                secondsRemaining: 20,
                onAccept: () {},
                onDecline: () {},
              ),
            ),
          ),
        ),
      );

      // Shared fare display
      expect(find.text('₹160'), findsWidgets);

      // Per-person fare badge for party of 2
      expect(find.byKey(const Key('per_person_fare_badge')), findsOneWidget);
      expect(find.textContaining('₹80 / person (Party of 2)'), findsOneWidget);

      // Honest detour guarantee badge (7.5% <= 15%)
      expect(find.text('+7.5% Detour'), findsOneWidget);
      expect(find.text('≤ 15% Guaranteed'), findsOneWidget);

      // Co-passenger shares sum matching total route cost (160 + 110 + 110 = 380)
      expect(find.textContaining('Co-Passenger Shares (Exact Sum)'), findsOneWidget);
      expect(find.text('Total: ₹380'), findsOneWidget);
      expect(find.text('₹160.00'), findsOneWidget);
      expect(find.text('₹110.00'), findsNWidgets(2));
    });

    testWidgets('tapping Why am I paying this fare opens the explanation sheet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PooledRideOfferCard(
                offer: partyOffer,
                secondsRemaining: 20,
                onAccept: () {},
                onDecline: () {},
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byKey(const Key('why_am_i_paying_this_fare_button'));
      expect(buttonFinder, findsOneWidget);

      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verify that WhyAmIPayingSheet appeared in modal
      expect(find.byType(WhyAmIPayingSheet), findsOneWidget);
      expect(find.text('Why am I paying this fare?'), findsNWidgets(2));
      expect(find.byKey(const Key('solo_baseline_fare_row')), findsOneWidget);
      expect(find.byKey(const Key('total_pooled_route_cost_row')), findsOneWidget);
      expect(find.byKey(const Key('exact_sum_match_badge')), findsOneWidget);
    });
  });
}
