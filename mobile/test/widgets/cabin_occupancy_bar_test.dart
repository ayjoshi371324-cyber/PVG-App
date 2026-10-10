import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/widgets/cabin_occupancy_bar.dart';

void main() {
  group('CabinOccupancyBar Widget Tests', () {
    testWidgets('renders segmented bar with onboard, reserved, held, and free seats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CabinOccupancyBar(
              maxCapacity: 4,
              onboardSeats: 2,
              reservedSeats: 1,
              heldSeats: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Labels and counts
      expect(find.textContaining('Onboard: 2'), findsOneWidget);
      expect(find.textContaining('Reserved: 1'), findsOneWidget);
      expect(find.textContaining('Free: 1'), findsOneWidget);

      // Bar exists
      expect(find.byKey(const Key('cabin_occupancy_bar_container')), findsOneWidget);
    });

    testWidgets('renders all held and full states correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CabinOccupancyBar(
              maxCapacity: 6,
              onboardSeats: 3,
              reservedSeats: 1,
              heldSeats: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Onboard: 3'), findsOneWidget);
      expect(find.textContaining('Reserved: 1'), findsOneWidget);
      expect(find.textContaining('Held: 2'), findsOneWidget);
      expect(find.textContaining('Free: 0'), findsOneWidget);
    });
  });
}
