import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/role/role_cubit.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';

void main() {
  group('RoleCubit', () {
    late RoleCubit roleCubit;

    setUp(() {
      roleCubit = RoleCubit();
    });

    tearDown(() {
      roleCubit.close();
    });

    test('initial state is AppRole.passenger', () {
      expect(roleCubit.state.currentRole, equals(AppRole.passenger));
      expect(roleCubit.state.previousRole, isNull);
    });

    test('selectRole transitions to driver mode', () {
      roleCubit.selectRole(AppRole.driver);
      expect(roleCubit.state.currentRole, equals(AppRole.driver));
      expect(roleCubit.state.previousRole, equals(AppRole.passenger));
    });

    test('selectRole transitions to ops mode', () {
      roleCubit.selectRole(AppRole.ops);
      expect(roleCubit.state.currentRole, equals(AppRole.ops));
      expect(roleCubit.state.previousRole, equals(AppRole.passenger));
    });

    test('selecting the same role does not emit new distinct state', () {
      final initial = roleCubit.state;
      roleCubit.selectRole(AppRole.passenger);
      expect(roleCubit.state, equals(initial));
    });

    test('AppRole enum has accurate display metadata', () {
      expect(AppRole.passenger.label, 'Passenger');
      expect(AppRole.driver.label, 'Driver');
      expect(AppRole.ops.label, 'Operations');
    });
  });
}
