import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/driver/driver_cubit.dart';
import 'package:ridepool_app/blocs/driver/driver_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
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

    test('confirmPickup without OTP verification is ignored and does not advance stop', () {
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.currentStop?.isPickup, isTrue);
      expect(driverCubit.state.isCurrentStopVerified, isFalse);

      driverCubit.confirmPickup();

      // Stop should NOT advance because OTP was not verified
      expect(driverCubit.state.currentStopIndex, equals(0));
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.stops[0].status, equals(DriverStopStatus.current));
    });

    test('confirmPickup increments cabin occupancy and assigns seats when verified', () {
      expect(driverCubit.state.currentOccupancy, equals(0));
      expect(driverCubit.state.currentStop?.isPickup, isTrue);

      driverCubit.bypassOtp();
      expect(driverCubit.state.isCurrentStopVerified, isTrue);

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
      driverCubit.bypassOtp();
      driverCubit.confirmPickup();
      expect(driverCubit.state.currentOccupancy, equals(1));

      // Pick up Pooja (2 seats)
      driverCubit.bypassOtp();
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
      driverCubit.bypassOtp();
      driverCubit.confirmPickup();
      // Pick up Pooja (2)
      driverCubit.bypassOtp();
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
      driverCubit.bypassOtp();
      driverCubit.confirmPickup();
      // 2. Pickup Pooja (2)
      driverCubit.bypassOtp();
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
      driverCubit.bypassOtp();
      driverCubit.confirmPickup();
      driverCubit.bypassOtp();
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

    group('OTP Entry Keypad, Verification & Stop Lockout', () {
      test('enterOtpDigit appends digits and deletes correctly', () {
        expect(driverCubit.state.enteredOtp, isEmpty);

        driverCubit.enterOtpDigit('4');
        driverCubit.enterOtpDigit('8');
        expect(driverCubit.state.enteredOtp, equals('48'));

        driverCubit.deleteOtpDigit();
        expect(driverCubit.state.enteredOtp, equals('4'));

        driverCubit.clearOtp();
        expect(driverCubit.state.enteredOtp, isEmpty);
      });

      test('entering 4th correct digit auto-triggers successful verification and shifts seat ledger', () {
        // Stop 1 expected code is #4821
        expect(driverCubit.state.seatLedger?.reserved, equals(3));
        expect(driverCubit.state.seatLedger?.occupied, equals(0));

        driverCubit.enterOtpDigit('4');
        driverCubit.enterOtpDigit('8');
        driverCubit.enterOtpDigit('2');
        driverCubit.enterOtpDigit('1');

        expect(driverCubit.state.isCurrentStopVerified, isTrue);
        expect(driverCubit.state.isStopLocked, isFalse);
        expect(driverCubit.state.otpErrorMessage, isNull);
        // SeatLedger transitioned pax-1 from reserved to occupied!
        expect(driverCubit.state.seatLedger?.reserved, equals(2));
        expect(driverCubit.state.seatLedger?.occupied, equals(1));
      });

      test('entering wrong OTP increments failed attempts and records error message', () {
        driverCubit.enterOtpDigit('9');
        driverCubit.enterOtpDigit('9');
        driverCubit.enterOtpDigit('9');
        driverCubit.enterOtpDigit('9');

        expect(driverCubit.state.isCurrentStopVerified, isFalse);
        expect(driverCubit.state.otpFailedAttempts, equals(1));
        expect(driverCubit.state.isStopLocked, isFalse);
        expect(driverCubit.state.otpErrorMessage, contains('4 attempts remaining'));
      });

      test('5 consecutive failed OTP entries locks the stop', () {
        for (int i = 0; i < 5; i++) {
          driverCubit.clearOtp();
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
        }

        expect(driverCubit.state.otpFailedAttempts, equals(5));
        expect(driverCubit.state.isStopLocked, isTrue);
        expect(driverCubit.state.otpErrorMessage, contains('Stop locked'));

        // Further entry is blocked while locked
        driverCubit.enterOtpDigit('4');
        expect(driverCubit.state.enteredOtp, equals('0000'));
      });

      test('manualUnlockStop clears lockout and resets failed attempts', () {
        for (int i = 0; i < 5; i++) {
          driverCubit.clearOtp();
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
          driverCubit.enterOtpDigit('0');
        }
        expect(driverCubit.state.isStopLocked, isTrue);

        driverCubit.manualUnlockStop();
        expect(driverCubit.state.isStopLocked, isFalse);
        expect(driverCubit.state.otpFailedAttempts, equals(0));
        expect(driverCubit.state.enteredOtp, isEmpty);
      });
    });

    test('receives mid-trip join proposal and approval inserts stops into driver manifest', () {
      final initialStopCount = driverCubit.state.stops.length;

      final stopPickup = DriverStop(
        id: 'stop-join-p',
        passengerId: 'pax-join-1',
        passengerName: 'Vikram S.',
        stopType: DriverStopType.pickup,
        location: PuneLandmarks.kothrud,
        seats: 1,
        verificationCode: '#5521',
      );

      final stopDropoff = DriverStop(
        id: 'stop-join-d',
        passengerId: 'pax-join-1',
        passengerName: 'Vikram S.',
        stopType: DriverStopType.dropoff,
        location: PuneLandmarks.hinjawadiPhase1,
        seats: 1,
        verificationCode: '#5521',
      );

      driverCubit.receiveJoinProposal(
        pickupStop: stopPickup,
        dropoffStop: stopDropoff,
      );

      expect(driverCubit.state.pendingPickupStop, equals(stopPickup));
      expect(driverCubit.state.pendingDropoffStop, equals(stopDropoff));

      // Approve proposal
      driverCubit.approveJoinProposal();

      expect(driverCubit.state.pendingPickupStop, isNull);
      expect(driverCubit.state.stops.length, equals(initialStopCount + 2));
      expect(
        driverCubit.state.stops.any((s) => s.passengerName == 'Vikram S.'),
        isTrue,
      );
    });

    test('rejectJoinProposal clears proposed stops without altering driver manifest', () {
      final initialStopCount = driverCubit.state.stops.length;

      final stopPickup = DriverStop(
        id: 'stop-join-p',
        passengerId: 'pax-join-1',
        passengerName: 'Vikram S.',
        stopType: DriverStopType.pickup,
        location: PuneLandmarks.kothrud,
        seats: 1,
        verificationCode: '#5521',
      );

      final stopDropoff = DriverStop(
        id: 'stop-join-d',
        passengerId: 'pax-join-1',
        passengerName: 'Vikram S.',
        stopType: DriverStopType.dropoff,
        location: PuneLandmarks.hinjawadiPhase1,
        seats: 1,
        verificationCode: '#5521',
      );

      driverCubit.receiveJoinProposal(
        pickupStop: stopPickup,
        dropoffStop: stopDropoff,
      );

      driverCubit.rejectJoinProposal();

      expect(driverCubit.state.pendingPickupStop, isNull);
      expect(driverCubit.state.stops.length, equals(initialStopCount));
    });

    test('cancelling a rider removes their pending stops from the driver manifest', () {
      // Pooja P. has pending pickup and dropoff (pax-2)
      driverCubit.cancelRider('pax-2');

      expect(
        driverCubit.state.stops.any((s) => s.passengerId == 'pax-2'),
        isFalse,
      );
      // Aakash S. (pax-1) stops remain intact
      expect(
        driverCubit.state.stops.any((s) => s.passengerId == 'pax-1'),
        isTrue,
      );
    });
  });
}
