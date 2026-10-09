import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/driver/driver_cubit.dart';
import 'package:ridepool_app/blocs/driver/driver_state.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';

void main() {
  group('DriverCubit Unit Tests', () {
    late DriverCubit driverCubit;

    setUp(() {
      driverCubit = DriverCubit();
    });

    tearDown(() {
      driverCubit.close();
    });

    test('initializes with default vehicle, ordered stops, and empty cabin', () {
      final state = driverCubit.state;
      expect(state.vehicle.name, equals('Tata Tigor EV'));
      expect(state.vehicle.licensePlate, equals('MH 12 RN 8842'));
      expect(state.vehicle.maxSeats, equals(4));
      expect(state.currentOccupancy, equals(0));
      expect(state.stops.length, greaterThanOrEqualTo(4));
      expect(state.currentStopIndex, equals(0));
      expect(state.currentStop?.passengerName, equals('Aakash S.'));
      expect(state.currentStop?.isPickup, isTrue);
      expect(state.currentStop?.status, equals(DriverStopStatus.current));
      expect(state.shiftStatus, equals(DriverShiftStatus.online));
      expect(state.isCabinFull, isFalse);
    });

    test('confirmPickup increments cabin occupancy and assigns seats', () {
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.currentStop?.isPickup, isTrue);

      driverCubit.confirmPickup();

      final state = driverCubit.state;
      // First pickup was Aakash S. with 1 seat
      expect(state.currentOccupancy, equals(1));
      expect(state.stops[0].status, equals(DriverStopStatus.completed));
      expect(state.currentStopIndex, equals(1));
      expect(state.currentStop?.passengerName, equals('Pooja P.'));
      expect(state.currentStop?.isPickup, isTrue);
      expect(state.currentStop?.status, equals(DriverStopStatus.current));

      // Cabin seat check
      final occupiedSeats = state.cabinSeats.where((s) => s.isOccupied).toList();
      expect(occupiedSeats.length, equals(1));
      expect(occupiedSeats.first.passengerName, equals('Aakash S.'));
    });

    test('confirmPickup for second stop increases occupancy correctly', () {
      // Pick up Aakash (1 seat)
      driverCubit.confirmPickup();
      expect(driverCubit.state.currentOccupancy, equals(1));

      // Pick up Pooja (2 seats)
      driverCubit.confirmPickup();
      final state = driverCubit.state;
      expect(state.currentOccupancy, equals(3));
      expect(state.stops[1].status, equals(DriverStopStatus.completed));
      expect(state.currentStopIndex, equals(2));
      expect(state.currentStop?.isDropoff, isTrue);
      expect(state.currentStop?.passengerName, equals('Aakash S.'));

      final occupiedSeats = state.cabinSeats.where((s) => s.isOccupied).toList();
      expect(occupiedSeats.length, equals(3));
    });

    test('confirmDropoff decrements cabin occupancy and frees seats', () {
      // Pick up Aakash (1)
      driverCubit.confirmPickup();
      // Pick up Pooja (2)
      driverCubit.confirmPickup();
      expect(driverCubit.state.currentOccupancy, equals(3));

      // Drop off Aakash (1 seat)
      driverCubit.confirmDropoff();
      final state = driverCubit.state;
      expect(state.currentOccupancy, equals(2));
      expect(state.stops[2].status, equals(DriverStopStatus.completed));
      expect(state.currentStopIndex, equals(3));
      expect(state.currentStop?.passengerName, equals('Pooja P.'));

      final occupiedSeats = state.cabinSeats.where((s) => s.isOccupied).toList();
      expect(occupiedSeats.length, equals(2));
      expect(occupiedSeats.every((s) => s.passengerName == 'Pooja P.'), isTrue);
    });

    test('completing all stops transitions shift to routeCompleted', () {
      // 1. Pickup Aakash (1)
      driverCubit.confirmPickup();
      // 2. Pickup Pooja (2)
      driverCubit.confirmPickup();
      // 3. Dropoff Aakash (1)
      driverCubit.confirmDropoff();
      // 4. Dropoff Pooja (2)
      driverCubit.confirmDropoff();

      final state = driverCubit.state;
      expect(state.currentOccupancy, equals(0));
      expect(state.isRouteCompleted, isTrue);
      expect(state.shiftStatus, equals(DriverShiftStatus.routeCompleted));
      expect(state.completedStopsCount, equals(state.stops.length));
      expect(state.remainingStopsCount, equals(0));
      expect(state.currentStop, isNull);
    });

    test('resetRoute resets stops, index, and occupancy back to initial state', () {
      driverCubit.confirmPickup();
      driverCubit.confirmPickup();
      expect(driverCubit.state.currentOccupancy, equals(3));

      driverCubit.resetRoute();

      final state = driverCubit.state;
      expect(state.currentOccupancy, equals(0));
      expect(state.currentStopIndex, equals(0));
      expect(state.stops.first.status, equals(DriverStopStatus.current));
      expect(state.shiftStatus, equals(DriverShiftStatus.online));
      expect(state.cabinSeats.every((s) => !s.isOccupied), isTrue);
    });
  });
}
