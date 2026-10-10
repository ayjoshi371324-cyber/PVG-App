import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/services/auth_service.dart';
import 'package:ridepool_app/services/token_storage_service.dart';
import 'package:ridepool_app/views/auth/auth_welcome_view.dart';
import 'package:ridepool_app/views/auth/driver_register_view.dart';
import 'package:ridepool_app/views/auth/login_view.dart';
import 'package:ridepool_app/views/auth/passenger_register_view.dart';

void main() {
  group('Auth Views Integration Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit(
        authService: MockAuthService(),
        tokenStorage: MemoryTokenStorageService(),
      );
    });

    tearDown(() {
      authCubit.close();
    });

    Widget createAuthWrapper(Widget child) {
      return MaterialApp(
        theme: UberTheme.lightTheme,
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: child,
        ),
      );
    }

    testWidgets('AuthWelcomeView renders hero, buttons, and evaluator 1-tap sign-ins', (tester) async {
      await tester.pumpWidget(createAuthWrapper(const AuthWelcomeView()));
      await tester.pumpAndSettle();

      expect(find.text('RouteMates'), findsOneWidget);
      expect(find.text('Algorithmic Carpooling for Pune'), findsOneWidget);
      expect(find.byKey(const Key('auth_passenger_signin_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_driver_onboard_button')), findsOneWidget);

      // Evaluator buttons
      expect(find.byKey(const Key('demo_login_passenger_button')), findsOneWidget);
      expect(find.byKey(const Key('demo_login_driver_button')), findsOneWidget);
      expect(find.byKey(const Key('demo_login_ops_button')), findsOneWidget);

      // Tap demo driver button
      await tester.tap(find.byKey(const Key('demo_login_driver_button')));
      await tester.pumpAndSettle();

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.role, equals(UserRole.driver));
    });

    testWidgets('LoginView submits email and password to AuthCubit', (tester) async {
      await tester.pumpWidget(createAuthWrapper(const LoginView()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.byKey(const Key('login_password_input')), findsOneWidget);

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(authCubit.state, isA<Authenticated>());
    });

    testWidgets('PassengerRegisterView creates passenger account', (tester) async {
      await tester.pumpWidget(createAuthWrapper(const PassengerRegisterView()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('register_name_input')), 'Aarav Nair');
      await tester.enterText(find.byKey(const Key('register_email_input')), 'aarav@example.com');
      await tester.enterText(find.byKey(const Key('register_password_input')), 'securepass123');

      await tester.tap(find.byKey(const Key('register_passenger_submit_button')));
      await tester.pumpAndSettle();

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.name, equals('Aarav Nair'));
      expect(authState.user.role, equals(UserRole.passenger));
    });

    testWidgets('DriverRegisterView captures vehicle tier, plate, and license number', (tester) async {
      await tester.pumpWidget(createAuthWrapper(const DriverRegisterView()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('driver_name_input')), findsOneWidget);
      expect(find.byKey(const Key('driver_plate_input')), findsOneWidget);
      expect(find.byKey(const Key('driver_license_input')), findsOneWidget);
      expect(find.byKey(const Key('driver_tier_chip_car')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('register_driver_submit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('register_driver_submit_button')));
      await tester.pumpAndSettle();

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.role, equals(UserRole.driver));
      expect(authState.user.licensePlate, equals('MH 12 RN 8842'));
      expect(authState.user.driverLicenseNumber, equals('DL-MH12-2022-9842'));
    });
  });
}
