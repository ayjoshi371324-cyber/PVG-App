import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/widgets/vehicle_tier_selector.dart';

void main() {
  group('VehicleTierSelector Widget', () {
    testWidgets('renders Auto, Car, and Car XL with rates and seat capacities', (tester) async {
      VehicleTier selected = VehicleTier.car;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return VehicleTierSelector(
                  selectedTier: selected,
                  partySize: 1,
                  distanceKm: 10.0,
                  onTierSelected: (tier) {
                    setState(() {
                      selected = tier;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify all 3 tiers are rendered
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Car XL'), findsOneWidget);

      // Verify seat capacity badges
      expect(find.textContaining('3 seats'), findsOneWidget);
      expect(find.textContaining('4 seats'), findsOneWidget);
      expect(find.textContaining('6 seats'), findsOneWidget);

      // Verify real-time estimated fares (10 km: Auto=₹96, Car=₹120, Car XL=₹168)
      expect(find.text('₹96'), findsOneWidget);
      expect(find.text('₹120'), findsOneWidget);
      expect(find.text('₹168'), findsOneWidget);

      // Tap Auto card to change selection
      await tester.tap(find.byKey(const Key('vehicle_tier_auto')));
      await tester.pumpAndSettle();
      expect(selected, equals(VehicleTier.auto));
    });

    testWidgets('visibly disables Auto when party size is 4 with helper text', (tester) async {
      VehicleTier selected = VehicleTier.car;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return VehicleTierSelector(
                  selectedTier: selected,
                  partySize: 4, // Exceeds Auto (3 seats)
                  distanceKm: 10.0,
                  onTierSelected: (tier) {
                    setState(() {
                      selected = tier;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Auto displays explanatory disabled helper text
      expect(find.textContaining('Max 3 seats (party size: 4)'), findsOneWidget);

      // Attempting to tap disabled Auto does not select it
      await tester.tap(find.byKey(const Key('vehicle_tier_auto')));
      await tester.pumpAndSettle();
      expect(selected, equals(VehicleTier.car)); // Remains Car

      // Car XL is enabled
      await tester.tap(find.byKey(const Key('vehicle_tier_car_xl')));
      await tester.pumpAndSettle();
      expect(selected, equals(VehicleTier.carXl));
    });

    testWidgets('visibly disables Auto and Car when party size is 5 with helper text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: VehicleTierSelector(
              selectedTier: VehicleTier.carXl,
              partySize: 5, // Exceeds Auto (3) and Car (4)
              distanceKm: 10.0,
              onTierSelected: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('Max 3 seats (party size: 5)'), findsOneWidget);
      expect(find.textContaining('Max 4 seats (party size: 5)'), findsOneWidget);
    });
  });
}
