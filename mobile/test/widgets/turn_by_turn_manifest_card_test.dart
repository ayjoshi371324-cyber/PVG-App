import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';
import 'package:ridepool_app/widgets/turn_by_turn_manifest_card.dart';

void main() {
  group('TurnByTurnManifestCard Widget Tests', () {
    final testStops = [
      const DriverStop(
        id: 'stop-1',
        passengerId: 'pax-1',
        passengerName: 'Aakash S.',
        stopType: DriverStopType.pickup,
        location: PuneLandmarks.kothrud,
        seats: 1,
        verificationCode: '#4821',
        etaMinutes: 3,
        distanceKm: 0.8,
        status: DriverStopStatus.current,
      ),
      const DriverStop(
        id: 'stop-2',
        passengerId: 'pax-2',
        passengerName: 'Pooja P.',
        stopType: DriverStopType.pickup,
        location: PuneLandmarks.shivajiNagar,
        seats: 2,
        verificationCode: '#9104',
        etaMinutes: 8,
        distanceKm: 3.2,
        status: DriverStopStatus.pending,
      ),
      const DriverStop(
        id: 'stop-3',
        passengerId: 'pax-1',
        passengerName: 'Aakash S.',
        stopType: DriverStopType.dropoff,
        location: PuneLandmarks.hinjawadiPhase1,
        seats: 1,
        verificationCode: '#4821',
        etaMinutes: 18,
        distanceKm: 9.4,
        status: DriverStopStatus.pending,
      ),
    ];

    testWidgets('renders all stops in manifest with passenger and ETA details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TurnByTurnManifestCard(
                stops: testStops,
                currentStopIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route Stop Manifest'), findsOneWidget);
      expect(find.text('Aakash S. (1 Seat)'), findsNWidgets(2));
      expect(find.text('Pooja P. (2 Seats)'), findsOneWidget);
      expect(find.text('Kothrud Stand'), findsOneWidget);
      expect(find.text('Shivaji Nagar'), findsOneWidget);
      expect(find.text('#4821'), findsAtLeastNWidgets(1));
      expect(find.text('#9104'), findsOneWidget);
      expect(find.text('Active Target'), findsOneWidget);
    });

    testWidgets('marks completed stops distinctly', (tester) async {
      final updatedStops = [
        testStops[0].copyWith(status: DriverStopStatus.completed),
        testStops[1].copyWith(status: DriverStopStatus.current),
        testStops[2],
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TurnByTurnManifestCard(
                stops: updatedStops,
                currentStopIndex: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Active Target'), findsOneWidget);
    });
  });
}
