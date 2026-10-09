import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/shapley_fare_breakdown_card.dart';

void main() {
  group('DetourGuaranteeBadge', () {
    testWidgets('renders exact detour percentage and <= 15% guarantee certification', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DetourGuaranteeBadge(
                detourPercentage: 8.4,
              ),
            ),
          ),
        ),
      );

      expect(find.text('+8.4% Detour'), findsOneWidget);
      expect(find.text('≤ 15% Guaranteed'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });
  });

  group('ShapleyFareBreakdownCard', () {
    testWidgets('renders baseline solo fare, shared fare, and net savings', (tester) async {
      final breakdown = ShapleyFareBreakdown(
        soloFare: 280.0,
        sharedFare: 196.0,
        coalitionSize: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: ShapleyFareBreakdownCard(
                breakdown: breakdown,
              ),
            ),
          ),
        ),
      );

      // Hero amounts
      expect(find.text('₹196'), findsNWidgets(2)); // Shared fare (hero & row)
      expect(find.text('₹280'), findsWidgets); // Solo baseline fare
      expect(find.text('Save ₹84 (30% off)'), findsOneWidget); // Savings pill
      expect(find.textContaining('Shapley'), findsWidgets);
    });
  });

  group('PooledRideOfferCard', () {
    late PooledRideOffer sampleOffer;

    setUp(() {
      sampleOffer = PooledRideOffer(
        offerId: 'offer-tigor-001',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        coPassengerLabels: const ['Rohan (Swargate)', 'Priya (Kothrud)'],
        detourPercentage: 8.4,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 196.0,
          coalitionSize: 3,
        ),
        offerExpirySeconds: 18,
      );
    });

    testWidgets('renders full offer details and triggers accept/decline callbacks', (tester) async {
      bool accepted = false;
      bool declined = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PooledRideOfferCard(
                offer: sampleOffer,
                secondsRemaining: 18,
                onAccept: () {
                  accepted = true;
                },
                onDecline: () {
                  declined = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify vehicle info & driver
      expect(find.text('Tata Tigor EV'), findsOneWidget);
      expect(find.text('MH-12-RN-4821'), findsOneWidget);
      expect(find.textContaining('Suresh K.'), findsOneWidget);
      expect(find.textContaining('4.9'), findsOneWidget);

      // Verify detour badge & Shapley breakdown
      expect(find.byType(DetourGuaranteeBadge), findsOneWidget);
      expect(find.byType(ShapleyFareBreakdownCard), findsOneWidget);

      // Verify expiry timer countdown
      expect(find.text('Expires in 18s'), findsOneWidget);

      // Verify co-passenger count
      expect(find.text('2 Co-passengers sharing route'), findsOneWidget);

      // Test Decline button tap
      final declineButtonFinder = find.byKey(const Key('decline_pool_offer_button'));
      expect(declineButtonFinder, findsOneWidget);
      await tester.tap(declineButtonFinder);
      await tester.pump();
      expect(declined, isTrue);

      // Test Accept button tap
      final acceptButtonFinder = find.byKey(const Key('accept_pool_offer_button'));
      expect(acceptButtonFinder, findsOneWidget);
      await tester.tap(acceptButtonFinder);
      await tester.pump();
      expect(accepted, isTrue);
    });
  });
}
