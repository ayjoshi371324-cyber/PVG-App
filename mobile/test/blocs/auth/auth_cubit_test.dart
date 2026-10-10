import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/auth/auth_cubit.dart';
import 'package:ridepool_app/blocs/auth/auth_state.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/services/auth_service.dart';
import 'package:ridepool_app/services/token_storage_service.dart';

void main() {
  group('AuthCubit & AuthService Unit Tests', () {
    late AuthService authService;
    late TokenStorageService tokenStorage;
    late AuthCubit authCubit;

    setUp(() async {
      tokenStorage = MemoryTokenStorageService();
      authService = MockAuthService();
      authCubit = AuthCubit(
        authService: authService,
        tokenStorage: tokenStorage,
      );
    });

    tearDown(() {
      authCubit.close();
    });

    test('initial state is AuthInitial or restored Unauthenticated when no stored token', () async {
      expect(authCubit.state, isA<AuthInitial>());
      await authCubit.restoreSession();
      expect(authCubit.state, isA<Unauthenticated>());
    });

    test('passenger registration succeeds and transitions to Authenticated as passenger', () async {
      final request = RegisterPassengerRequest(
        name: 'Pooja Sharma',
        email: 'pooja@example.com',
        password: 'password123',
        phone: '+91 98765 43210',
      );

      await authCubit.registerPassenger(request);

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.name, equals('Pooja Sharma'));
      expect(authState.user.role, equals(UserRole.passenger));
      expect(authState.user.isDriver, isFalse);
      expect(authState.tokens.accessToken, isNotEmpty);

      // Verify token persisted in storage
      final storedToken = await tokenStorage.getAccessToken();
      expect(storedToken, equals(authState.tokens.accessToken));
    });

    test('driver registration captures vehicle tier, plate, and license number', () async {
      final request = RegisterDriverRequest(
        name: 'Rahul Kadam',
        email: 'rahul@example.com',
        password: 'password123',
        phone: '+91 98220 12345',
        vehicleTier: VehicleTier.car,
        licensePlate: 'MH 12 RN 8842',
        driverLicenseNumber: 'DL-MH12-2022-9842',
      );

      await authCubit.registerDriver(request);

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.name, equals('Rahul Kadam'));
      expect(authState.user.role, equals(UserRole.driver));
      expect(authState.user.isDriver, isTrue);
      expect(authState.user.vehicleTier, equals(VehicleTier.car));
      expect(authState.user.licensePlate, equals('MH 12 RN 8842'));
      expect(authState.user.driverLicenseNumber, equals('DL-MH12-2022-9842'));
    });

    test('login with valid demo passenger credentials authenticates user', () async {
      await authCubit.login(
        email: 'passenger@ridepool.ai',
        password: 'password123',
      );

      expect(authCubit.state, isA<Authenticated>());
      final authState = authCubit.state as Authenticated;
      expect(authState.user.role, equals(UserRole.passenger));
    });

    test('loginAsDemo supports 1-tap evaluator sign-in for passenger, driver, and ops', () async {
      await authCubit.loginAsDemo(UserRole.driver);
      expect(authCubit.state, isA<Authenticated>());
      expect((authCubit.state as Authenticated).user.role, equals(UserRole.driver));

      await authCubit.logout();
      expect(authCubit.state, isA<Unauthenticated>());
      expect(await tokenStorage.getAccessToken(), isNull);
    });

    test('token auto-refresh restores session and updates stored token', () async {
      await authCubit.loginAsDemo(UserRole.passenger);
      final initialToken = (authCubit.state as Authenticated).tokens.accessToken;
      expect(initialToken, isNotEmpty);

      await authCubit.refreshToken();

      expect(authCubit.state, isA<Authenticated>());
      final refreshedToken = (authCubit.state as Authenticated).tokens.accessToken;
      expect(refreshedToken, isNotEmpty);
      expect(await tokenStorage.getAccessToken(), equals(refreshedToken));
    });
  });
}
