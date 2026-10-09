import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/widgets/detour_guarantee_inspector.dart';

void main() {
  group('DetourGuaranteeInspector Widget Tests', () {
    final records = [
      const ActiveRouteDetourRecord(
        routeId: 'R-101',
        vehicleId: 'EV-02',
        directDistanceKm: 16.2,
        pooledDistanceKm: 17.2,
      ),
      const ActiveRouteDetourRecord(
        routeId: 'R-102',
        vehicleId: 'EV-03',
        directDistanceKm: 14.5,
        pooledDistanceKm: 15.8,
      ),
    ];

    testWidgets('renders 100% compliance badge and active route breakdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: DetourGuaranteeInspector(
                records: records,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detour Bounds Guarantee'), findsOneWidget);
      expect(find.text('100.0% Compliant'), findsOneWidget);
      expect(find.text('R-101'), findsOneWidget);
      expect(find.text('R-102'), findsOneWidget);
      expect(find.text('PASS (<= 15%)'), findsNWidgets(2));
      expect(find.textContaining('15.0% Ceiling'), findsOneWidget);
    });
  });
}
