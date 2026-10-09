import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/trip_receipt_card.dart';

void main() {
  group('TripReceiptCard', () {
    final sampleReceipt = TripReceipt(
      receiptId: 'rcpt-test-1',
      tripId: 'trip-test-1',
      vehicleModel: 'Tata Tigor EV',
      licensePlate: 'MH-12-RN-4821',
      driverName: 'Suresh K.',
      pickup: PuneLandmarks.kothrud,
      dropoff: PuneLandmarks.hinjawadiPhase1,
      completedAt: DateTime.parse('2026-10-10 10:30:00'),
      soloReferenceFare: 280.0,
      finalPayableFare: 171.0,
      finalDetourPercentage: 11.5,
      environmentalImpact: const EnvironmentalImpact(
        vehicleKmSaved: 8.4,
        co2SavedKg: 1.0,
      ),
      coalitionAudits: const [
        CoalitionMemberAudit(
          passengerName: 'You',
          isUser: true,
          soloFare: 280.0,
          marginalContribution: 110.0,
          shapleyFairShare: 171.0,
        ),
        CoalitionMemberAudit(
          passengerName: 'Aarav',
          isUser: false,
          soloFare: 240.0,
          marginalContribution: 95.0,
          shapleyFairShare: 145.0,
        ),
      ],
    );

    Widget buildTestWidget({
      required TripReceipt receipt,
      VoidCallback? onDone,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TripReceiptCard(
              receipt: receipt,
              onDone: onDone ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders hero pricing, driver details, and environmental impact',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));

      // Fare details
      expect(find.text('₹171'), findsWidgets);
      expect(find.text('₹280'), findsOneWidget);
      expect(find.textContaining('Save ₹109'), findsOneWidget);
      expect(find.textContaining('39% off'), findsOneWidget);

      // Vehicle and driver
      expect(find.textContaining('Tata Tigor EV'), findsOneWidget);
      expect(find.textContaining('Suresh K.'), findsOneWidget);

      // Environmental metrics
      expect(find.textContaining('1.0 kg CO₂'), findsOneWidget);
      expect(find.textContaining('8.4 km'), findsOneWidget);

      // Detour badge
      expect(find.textContaining('11.5%'), findsOneWidget);
      expect(find.textContaining('Guaranteed'), findsOneWidget);
    });

    testWidgets('toggles Shapley coalition cost audit breakdown table',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));

      final toggleFinder = find.byKey(const Key('shapley_audit_toggle'));
      expect(toggleFinder, findsOneWidget);

      // Tap toggle to expand
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Check member rows
      expect(find.text('You (User)'), findsOneWidget);
      expect(find.text('Aarav'), findsOneWidget);
      expect(find.textContaining('MC: ₹110'), findsOneWidget);
      expect(find.textContaining('Fair Share: ₹171'), findsOneWidget);
    });

    testWidgets('invokes onDone when receipt done button is tapped',
        (tester) async {
      var doneCalled = false;
      await tester.pumpWidget(buildTestWidget(
        receipt: sampleReceipt,
        onDone: () {
          doneCalled = true;
        },
      ));

      final doneButton = find.byKey(const Key('receipt_done_button'));
      expect(doneButton, findsOneWidget);

      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(doneCalled, isTrue);
    });
  });
}
