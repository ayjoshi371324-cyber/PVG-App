import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/core/route_estimator.dart';

void main() {
  group('PassengerCubit', () {
    late PassengerCubit cubit;

    setUp(() {
      cubit = PassengerCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has default preset pickup and dropoff with route estimate', () {
      expect(cubit.state.pickup, isNotNull);
      expect(cubit.state.dropoff, isNotNull);
      expect(cubit.state.estimate, isNotNull);
      expect(cubit.state.estimate!.distanceKm, greaterThan(0));
    });

    test('setPickup recalculates route estimate', () {
      final initialDropoff = cubit.state.dropoff;
      cubit.setPickup(PuneLandmarks.koregaonPark);

      expect(cubit.state.pickup, equals(PuneLandmarks.koregaonPark));
      expect(cubit.state.dropoff, equals(initialDropoff));
      expect(cubit.state.estimate!.pickup, equals(PuneLandmarks.koregaonPark));
    });

    test('setDropoff recalculates route estimate', () {
      cubit.setDropoff(PuneLandmarks.swargate);

      expect(cubit.state.dropoff, equals(PuneLandmarks.swargate));
      expect(cubit.state.estimate!.dropoff, equals(PuneLandmarks.swargate));
    });

    test('swapLocations switches pickup and dropoff and recalculates', () {
      final oldPickup = cubit.state.pickup;
      final oldDropoff = cubit.state.dropoff;

      cubit.swapLocations();

      expect(cubit.state.pickup, equals(oldDropoff));
      expect(cubit.state.dropoff, equals(oldPickup));
      expect(cubit.state.estimate!.pickup, equals(oldDropoff));
      expect(cubit.state.estimate!.dropoff, equals(oldPickup));
    });
  });
}
