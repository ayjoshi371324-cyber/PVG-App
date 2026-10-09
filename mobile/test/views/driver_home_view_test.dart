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
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Initial State: Stop 1 (Pickup Aakash)
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(find.text('Next Stop: Pickup Aakash S.'), findsOneWidget);
      expect(find.text('Confirm Passenger Boarded'), findsOneWidget);

      // Boarding button is disabled initially before OTP verification
      await tester.ensureVisible(find.text('Confirm Passenger Boarded'));
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();
      expect(driverCubit.state.currentStopIndex, equals(0));

      // Tap Bypass OTP (Demo) to verify
      await tester.ensureVisible(find.textContaining('Bypass OTP'));
      await tester.tap(find.textContaining('Bypass OTP'));
      await tester.pumpAndSettle();
      expect(driverCubit.state.isCurrentStopVerified, isTrue);

      // Now Confirm Passenger Boarded (Aakash)
      await tester.ensureVisible(find.text('Confirm Passenger Boarded'));
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();

      // 2. Stop 2: Pickup Pooja P. (2 seats)
      expect(driverCubit.state.currentOccupancy, equals(1));
      expect(find.text('Next Stop: Pickup Pooja P.'), findsOneWidget);
      expect(find.text('#9104'), findsAtLeastNWidgets(1));

      // Tap Bypass OTP (Demo) for Pooja
      await tester.ensureVisible(find.textContaining('Bypass OTP'));
      await tester.tap(find.textContaining('Bypass OTP'));
      await tester.pumpAndSettle();

      // Tap Confirm Passenger Boarded (Pooja)
      await tester.ensureVisible(find.text('Confirm Passenger Boarded'));
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();

      // 3. Stop 3: Dropoff Aakash S.
      expect(driverCubit.state.currentOccupancy, equals(3));
      expect(find.text('Next Stop: Dropoff Aakash S.'), findsOneWidget);
      expect(find.text('Confirm Passenger Dropped Off'), findsOneWidget);

      // Tap Confirm Passenger Dropped Off (Aakash)
      await tester.ensureVisible(find.text('Confirm Passenger Dropped Off'));
      await tester.tap(find.text('Confirm Passenger Dropped Off'));
      await tester.pumpAndSettle();

      // 4. Stop 4: Dropoff Pooja P.
      expect(driverCubit.state.currentOccupancy, equals(2));
      expect(find.text('Next Stop: Dropoff Pooja P.'), findsOneWidget);
      expect(find.text('Confirm Passenger Dropped Off'), findsOneWidget);

      // Tap Confirm Passenger Dropped Off (Pooja)
      await tester.ensureVisible(find.text('Confirm Passenger Dropped Off'));
      await tester.tap(find.text('Confirm Passenger Dropped Off'));
      await tester.pumpAndSettle();

      // 5. Route Completed
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.isRouteCompleted, isTrue);
      expect(find.text('Route Completed'), findsOneWidget);
      expect(find.text('Reset Demo Route'), findsOneWidget);

      // Tap Reset Demo Route
      await tester.ensureVisible(find.text('Reset Demo Route'));
      await tester.tap(find.text('Reset Demo Route'));
      await tester.pumpAndSettle();

      // Reverts back to initial Stop 1
      expect(driverCubit.state.currentStopIndex, equals(0));
      expect(find.text('Next Stop: Pickup Aakash S.'), findsOneWidget);
    });

    testWidgets('interactively enters OTP digits on keypad and confirms boarding', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Stop 1 code is #4821
      // Enter 4, 8, 2, 1 on keypad
      await tester.ensureVisible(find.text('4'));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(driverCubit.state.isCurrentStopVerified, isTrue);
      expect(find.textContaining('OTP Verified'), findsOneWidget);

      // Boarding enabled
      await tester.ensureVisible(find.text('Confirm Passenger Boarded'));
      await tester.tap(find.text('Confirm Passenger Boarded'));
      await tester.pumpAndSettle();
      expect(driverCubit.state.currentStopIndex, equals(1));
    });
  });
}
