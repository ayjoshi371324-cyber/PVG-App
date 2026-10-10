import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/shell_view.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/views/driver/driver_home_view.dart';
import 'package:ridepool_app/views/ops/ops_home_view.dart';
import 'package:ridepool_app/repositories/ride_pool_repository.dart';

void main() {
  group('ShellView and Role Navigation', () {
    late RoleCubit roleCubit;

    setUp(() {
      roleCubit = RoleCubit();
    });

    tearDown(() {
      roleCubit.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: UberTheme.lightTheme,
        home: BlocProvider<RoleCubit>.value(
          value: roleCubit,
          child: const ShellView(),
        ),
      );
    }

    testWidgets('initializes in Passenger Mode by default', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(PassengerHomeView), findsOneWidget);
      expect(find.byType(DriverHomeView), findsNothing);
      expect(find.byType(OpsHomeView), findsNothing);
    });

    testWidgets('switches to Driver Mode when Driver tab is selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Driver'));
      await tester.pumpAndSettle();

      expect(find.byType(PassengerHomeView), findsNothing);
      expect(find.byType(DriverHomeView), findsOneWidget);
      expect(find.byType(OpsHomeView), findsNothing);
    });

    testWidgets('switches to Operations Mode when Operations tab is selected', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Operations'));
      await tester.pumpAndSettle();

      expect(find.byType(PassengerHomeView), findsNothing);
      expect(find.byType(DriverHomeView), findsNothing);
      expect(find.byType(OpsHomeView), findsOneWidget);
    });

    testWidgets('Header Demo/Inspector switch grants instant access to Ops Fleet Console and returns', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially in Passenger mode
      expect(find.byType(PassengerHomeView), findsOneWidget);
      expect(find.byType(OpsHomeView), findsNothing);

      // Tap Header Demo/Inspector button
      expect(find.byKey(const Key('header_inspector_switch')), findsOneWidget);
      await tester.tap(find.byKey(const Key('header_inspector_switch')));
      await tester.pumpAndSettle();

      // Now instantly viewing Ops Fleet Console
      expect(find.byType(OpsHomeView), findsOneWidget);
      expect(find.textContaining('Inspector Mode Active'), findsOneWidget);

      // Tap Return to Session (or tap header switch again)
      await tester.tap(find.text('Return to Session'));
      await tester.pumpAndSettle();

      // Session intact, back to Passenger mode!
      expect(find.byType(PassengerHomeView), findsOneWidget);
      expect(find.byType(OpsHomeView), findsNothing);
    });

    testWidgets('Header Dual-Mode toggle switches between Offline Simulation and Live Backend', (tester) async {
      // Ensure clean state before test
      DualModeRidePoolRepository.instance.setMode(RepositoryMode.offlineSimulation);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('header_backend_mode_toggle')), findsOneWidget);
      expect(find.text('Offline Sim'), findsOneWidget);

      await tester.tap(find.byKey(const Key('header_backend_mode_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Live Backend'), findsOneWidget);
      expect(DualModeRidePoolRepository.instance.mode, equals(RepositoryMode.liveBackend));

      await tester.tap(find.byKey(const Key('header_backend_mode_toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Offline Sim'), findsOneWidget);
      expect(DualModeRidePoolRepository.instance.mode, equals(RepositoryMode.offlineSimulation));
    });
  });
}
