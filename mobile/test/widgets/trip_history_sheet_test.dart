import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/trip_history_sheet.dart';

void main() {
  group('TripHistorySheet', () {
    final sampleReceipt1 = TripReceipt(
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
      ],
    );

    final sampleReceipt2 = TripReceipt(
      receiptId: 'rcpt-test-2',
      tripId: 'trip-test-2',
      vehicleModel: 'MG ZS EV',
      licensePlate: 'MH-14-AA-9999',
      driverName: 'Amit P.',
      pickup: PuneLandmarks.shivajiNagar,
      dropoff: PuneLandmarks.vimanNagar,
      completedAt: DateTime.parse('2026-10-09 15:45:00'),
      soloReferenceFare: 350.0,
      finalPayableFare: 210.0,
      finalDetourPercentage: 9.0,
      environmentalImpact: const EnvironmentalImpact(
        vehicleKmSaved: 12.0,
        co2SavedKg: 1.44,
      ),
      coalitionAudits: const [],
    );

    Widget buildTestWidget({
      required List<TripReceipt> history,
      VoidCallback? onClose,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TripHistorySheet(
            history: history,
            onClose: onClose ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders empty state when trip history is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(history: []));

      expect(find.text('No Past Rides Yet'), findsOneWidget);
      expect(
        find.textContaining('Your completed pooling rides will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('renders past rides list with route and savings', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(history: [sampleReceipt1, sampleReceipt2]),
      );

      // Route titles
      expect(find.textContaining('Kothrud'), findsOneWidget);
      expect(find.textContaining('Shivaji Nagar'), findsOneWidget);
      expect(find.textContaining('Hinjawadi Phase 1'), findsOneWidget);
      expect(find.textContaining('Viman Nagar'), findsOneWidget);

      // Fares
      expect(find.text('₹171'), findsOneWidget);
      expect(find.text('₹210'), findsOneWidget);

      // CO2 badges
      expect(find.textContaining('1.0 kg CO₂ saved'), findsOneWidget);
      expect(find.textContaining('1.4 kg CO₂ saved'), findsOneWidget);
    });

    testWidgets('expands past trip card to view detailed Shapley receipt',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(history: [sampleReceipt1]),
      );

      final expandTile = find.byKey(const Key('history_item_rcpt-test-1'));
      expect(expandTile, findsOneWidget);

      await tester.tap(expandTile);
      await tester.pumpAndSettle();

      expect(find.textContaining('Suresh K.'), findsOneWidget);
      expect(find.textContaining('MH-12-RN-4821'), findsOneWidget);
      expect(find.textContaining('Shapley Cost Allocation Audit'), findsOneWidget);
    });

    testWidgets('calls onClose when close button is tapped', (tester) async {
      var closeCalled = false;
      await tester.pumpWidget(
        buildTestWidget(
          history: [sampleReceipt1],
          onClose: () {
            closeCalled = true;
          },
        ),
      );

      final closeBtn = find.byKey(const Key('close_history_button'));
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(closeCalled, isTrue);
    });
  });
}
