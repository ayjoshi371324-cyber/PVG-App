import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/shell_view.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/views/driver/driver_home_view.dart';
import 'package:ridepool_app/views/ops/ops_home_view.dart';

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
  });
}
