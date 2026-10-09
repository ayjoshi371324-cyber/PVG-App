import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/why_am_i_paying_sheet.dart';

void main() {
  group('WhyAmIPayingSheet Widget Tests', () {
    final testBreakdown = ShapleyFareBreakdown(
      soloFare: 180.0,
      sharedFare: 120.0,
      coalitionSize: 2,
      partySize: 2,
      perPersonFare: 60.0,
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

    testWidgets('renders all required Shapley game-theory components accurately',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WhyAmIPayingSheet(breakdown: testBreakdown),
            ),
          ),
        ),
      );

      // Header title & explanation
      expect(find.text('Why am I paying this fare?'), findsOneWidget);
      expect(
        find.textContaining('The system compares the cost of different passenger combinations'),
        findsOneWidget,
      );

      // Solo baseline fare & Total pooled route cost
      expect(find.byKey(const Key('solo_baseline_fare_row')), findsOneWidget);
      expect(find.text('₹180'), findsWidgets);
      expect(find.byKey(const Key('total_pooled_route_cost_row')), findsOneWidget);
      expect(find.text('₹260'), findsWidgets);

      // Fixed fee share
      expect(find.byKey(const Key('fixed_fee_share_row')), findsOneWidget);
      expect(find.text('₹10.00'), findsOneWidget);

      // Marginal contribution per passenger
      expect(find.byKey(const Key('marginal_contributions_section')), findsOneWidget);
      expect(find.text('Rider A (You)'), findsWidgets);
      expect(find.text('Rider B'), findsWidgets);

      // Characteristic function coalition table
      expect(find.byKey(const Key('coalition_table_section')), findsOneWidget);
      expect(find.textContaining('Rider A (You), Rider B'), findsWidgets);

      // Sum of all passenger shares matches total vehicle route cost
      expect(find.byKey(const Key('passenger_shares_section')), findsOneWidget);
      expect(find.byKey(const Key('exact_sum_match_badge')), findsOneWidget);
      expect(find.textContaining('Matches Total Route Cost: ₹260'), findsOneWidget);
    });

    testWidgets('displays per-person cost when party size is greater than 1',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WhyAmIPayingSheet(breakdown: testBreakdown),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('per_person_split_row')), findsOneWidget);
      expect(find.textContaining('₹60.00 / person (Party of 2)'), findsOneWidget);
    });
  });
}
