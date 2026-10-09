import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/landmark_chips.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/solo_estimate_card.dart';

void main() {
  group('LandmarkChips Widget', () {
    testWidgets('renders key Pune transit hub presets and triggers callback', (tester) async {
      String? selectedName;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: LandmarkChips(
              onLandmarkSelected: (loc) => selectedName = loc.name,
            ),
          ),
        ),
      );

      expect(find.text('Shivaji Nagar'), findsOneWidget);
      expect(find.text('Hinjawadi Phase 1'), findsOneWidget);
      expect(find.text('Koregaon Park'), findsOneWidget);
      expect(find.text('Swargate'), findsOneWidget);

      await tester.tap(find.text('Hinjawadi Phase 1'));
      await tester.pump();

      expect(selectedName, equals('Hinjawadi Phase 1'));
    });
  });

  group('SoloEstimateCard Widget', () {
    testWidgets('displays distance, duration, and reference solo fare', (tester) async {
      final estimate = const RouteEstimatorService().estimateRoute(
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SoloEstimateCard(estimate: estimate),
          ),
        ),
      );

      expect(find.text(estimate.formattedDistance), findsOneWidget);
      expect(find.text(estimate.formattedDuration), findsOneWidget);
      expect(find.text(estimate.formattedFare), findsOneWidget);
      expect(find.text('Solo Reference Fare'), findsOneWidget);
    });
  });

  group('PuneMapWidget', () {
    testWidgets('initializes FlutterMap with pickup and dropoff markers', (tester) async {
      final estimate = const RouteEstimatorService().estimateRoute(
        pickup: PuneLandmarks.shivajiNagar,
        dropoff: PuneLandmarks.swargate,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PuneMapWidget(
              pickup: PuneLandmarks.shivajiNagar,
              dropoff: PuneLandmarks.swargate,
              polylinePoints: estimate.polylinePoints,
            ),
          ),
        ),
      );

      expect(find.byType(FlutterMap), findsOneWidget);
      // Pickup circular marker
      expect(find.byKey(const Key('pickup_marker_dot')), findsOneWidget);
      // Dropoff square marker
      expect(find.byKey(const Key('dropoff_marker_square')), findsOneWidget);
    });
  });
}
