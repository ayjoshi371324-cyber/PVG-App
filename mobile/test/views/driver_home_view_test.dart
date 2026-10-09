import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/driver/driver_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/driver/driver_home_view.dart';
import 'package:ridepool_app/widgets/cabin_occupancy_gauge.dart';
import 'package:ridepool_app/widgets/turn_by_turn_manifest_card.dart';

void main() {
  group('DriverHomeView Integration Tests', () {
    late DriverCubit driverCubit;

    setUp(() {
      driverCubit = DriverCubit();
    });

    tearDown(() {
      driverCubit.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: UberTheme.lightTheme,
        home: BlocProvider<DriverCubit>.value(
          value: driverCubit,
          child: const DriverHomeView(),
        ),
      );
    }

    testWidgets('renders vehicle info, cabin gauge, and initial pickup stop', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check vehicle and shift badge
      expect(find.text('Tata Tigor EV'), findsAtLeastNWidgets(1));
      expect(find.textContaining('MH 12 RN 8842'), findsAtLeastNWidgets(1));
      expect(find.textContaining('84%'), findsOneWidget);

      // Check initial stop title & details
      expect(find.text('Next Stop: Pickup Aakash S.'), findsOneWidget);
      expect(find.textContaining('Kothrud Stand'), findsAtLeastNWidgets(1));
      expect(find.text('#4821'), findsAtLeastNWidgets(1));

      // Action button
      expect(find.text('Confirm Passenger Boarded'), findsOneWidget);

      // Check Cabin Occupancy Gauge & TurnByTurnManifestCard exist
      expect(find.byType(CabinOccupancyGauge), findsAtLeastNWidgets(1));
      expect(find.byType(TurnByTurnManifestCard), findsOneWidget);
    });

    testWidgets('walks through entire stop sequence from boarding to dropoff and completion', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Initial State: Stop 1 (Pickup Aakash)
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(find.text('Next Stop: Pickup Aakash S.'), findsOneWidget);
      expect(find.text('Confirm Passenger Boarded'), findsOneWidget);

      // Tap Confirm Passenger Boarded (Aakash)
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();

      // 2. Stop 2: Pickup Pooja P. (2 seats)
      expect(driverCubit.state.currentOccupancy, equals(1));
      expect(find.text('Next Stop: Pickup Pooja P.'), findsOneWidget);
      expect(find.text('#9104'), findsAtLeastNWidgets(1));

      // Tap Confirm Passenger Boarded (Pooja)
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();

      // 3. Stop 3: Dropoff Aakash S.
      expect(driverCubit.state.currentOccupancy, equals(3));
      expect(find.text('Next Stop: Dropoff Aakash S.'), findsOneWidget);
      expect(find.text('Confirm Passenger Dropped Off'), findsOneWidget);

      // Tap Confirm Passenger Dropped Off (Aakash)
      await tester.tap(find.text('Confirm Passenger Dropped Off'));
      await tester.pumpAndSettle();

      // 4. Stop 4: Dropoff Pooja P.
      expect(driverCubit.state.currentOccupancy, equals(2));
      expect(find.text('Next Stop: Dropoff Pooja P.'), findsOneWidget);
      expect(find.text('Confirm Passenger Dropped Off'), findsOneWidget);

      // Tap Confirm Passenger Dropped Off (Pooja)
      await tester.tap(find.text('Confirm Passenger Dropped Off'));
      await tester.pumpAndSettle();

      // 5. Route Completed
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.isRouteCompleted, isTrue);
      expect(find.text('Route Completed'), findsOneWidget);
      expect(find.text('Reset Demo Route'), findsOneWidget);

      // Tap Reset Demo Route
      await tester.tap(find.text('Reset Demo Route'));
      await tester.pumpAndSettle();

      // Reverts back to initial Stop 1
      expect(driverCubit.state.currentStopIndex, equals(0));
      expect(find.text('Next Stop: Pickup Aakash S.'), findsOneWidget);
    });
  });
}
