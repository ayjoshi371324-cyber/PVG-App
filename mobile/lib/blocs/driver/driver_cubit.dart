import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/driver/driver_state.dart';
import 'package:ridepool_app/core/engine/boarding_verification_engine.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';

class DriverCubit extends Cubit<DriverState> {
  DriverCubit({
    DriverVehicle? vehicle,
    List<DriverStop>? initialStops,
    this._verificationEngine = const BoardingVerificationEngine(),
  }) : super(_buildInitialState(vehicle, initialStops));

  final BoardingVerificationEngine _verificationEngine;

  static DriverState _buildInitialState(
    DriverVehicle? vehicle,
    List<DriverStop>? customStops,
  ) {
    final activeVehicle = vehicle ??
        const DriverVehicle(
          id: 'EV-04',
          name: 'Tata Tigor EV',
          licensePlate: 'MH 12 RN 8842',
          maxSeats: 4,
          batteryPercentage: 84,
        );

    final defaultStops = customStops ??
        [
          const DriverStop(
            id: 'stop-1',
            passengerId: 'pax-1',
            passengerName: 'Aakash S.',
            stopType: DriverStopType.pickup,
            location: PuneLandmarks.kothrud,
            seats: 1,
            verificationCode: '#4821',
            etaMinutes: 3,
            distanceKm: 0.8,
            status: DriverStopStatus.current,
          ),
          const DriverStop(
            id: 'stop-2',
            passengerId: 'pax-2',
            passengerName: 'Pooja P.',
            stopType: DriverStopType.pickup,
            location: PuneLandmarks.shivajiNagar,
            seats: 2,
            verificationCode: '#9104',
            etaMinutes: 8,
            distanceKm: 3.2,
            status: DriverStopStatus.pending,
          ),
          const DriverStop(
            id: 'stop-3',
            passengerId: 'pax-1',
            passengerName: 'Aakash S.',
            stopType: DriverStopType.dropoff,
            location: PuneLandmarks.hinjawadiPhase1,
            seats: 1,
            verificationCode: '#4821',
            etaMinutes: 18,
            distanceKm: 9.4,
            status: DriverStopStatus.pending,
          ),
          const DriverStop(
            id: 'stop-4',
            passengerId: 'pax-2',
            passengerName: 'Pooja P.',
            stopType: DriverStopType.dropoff,
            location: PuneLandmarks.hinjawadiPhase1,
            seats: 2,
            verificationCode: '#9104',
            etaMinutes: 22,
            distanceKm: 11.2,
            status: DriverStopStatus.pending,
          ),
        ];

    final initialCabinSeats = [
      const CabinSeat(seatIndex: 0, label: 'Front'),
      const CabinSeat(seatIndex: 1, label: 'Rear L'),
      const CabinSeat(seatIndex: 2, label: 'Rear C'),
      const CabinSeat(seatIndex: 3, label: 'Rear R'),
    ];

    SeatLedger ledger = SeatLedger.empty(capacity: activeVehicle.maxSeats);
    for (final stop in defaultStops) {
      if (stop.isPickup) {
        ledger = ledger.confirmSeats(
          bookingId: stop.passengerId,
          partySize: stop.seats,
        );
      }
    }

    return DriverState(
      vehicle: activeVehicle,
      stops: defaultStops,
      currentStopIndex: 0,
      shiftStatus: DriverShiftStatus.online,
      cabinSeats: initialCabinSeats,
      currentOccupancy: 0,
      seatLedger: ledger,
    );
  }

  void enterOtpDigit(String digit) {
    if (state.isStopLocked) return;
    if (state.isCurrentStopVerified) return;
    if (state.enteredOtp.length >= 4) return;

    final updated = '${state.enteredOtp}$digit';
    emit(state.copyWith(
      enteredOtp: updated,
      clearOtpErrorMessage: true,
    ));

    if (updated.length == 4) {
      verifyEnteredOtp();
    }
  }

  void deleteOtpDigit() {
    if (state.isStopLocked) return;
    if (state.isCurrentStopVerified) return;
    if (state.enteredOtp.isEmpty) return;

    emit(state.copyWith(
      enteredOtp: state.enteredOtp.substring(0, state.enteredOtp.length - 1),
      clearOtpErrorMessage: true,
    ));
  }

  void clearOtp() {
    if (state.isStopLocked) return;
    emit(state.copyWith(
      enteredOtp: '',
      clearOtpErrorMessage: true,
    ));
  }

  void verifyEnteredOtp() {
    final current = state.currentStop;
    if (current == null || !current.isPickup) return;
    if (state.isStopLocked) return;

    final result = _verificationEngine.verifyOtp(
      enteredOtp: state.enteredOtp,
      expectedOtp: current.verificationCode,
      currentFailedAttempts: state.otpFailedAttempts,
    );

    if (result.isSuccess) {
      final currentLedger = state.seatLedger ?? SeatLedger.empty(capacity: state.maxCapacity);
      final updatedLedger = _verificationEngine.boardPassenger(
        ledger: currentLedger,
        bookingId: current.passengerId,
        partySize: current.seats,
      );

      emit(state.copyWith(
        isCurrentStopVerified: true,
        clearOtpErrorMessage: true,
        otpFailedAttempts: 0,
        isStopLocked: false,
        seatLedger: updatedLedger,
      ));
    } else {
      emit(state.copyWith(
        isCurrentStopVerified: false,
        otpFailedAttempts: result.newFailedAttempts,
        isStopLocked: result.isLocked,
        otpErrorMessage: result.errorMessage,
      ));
    }
  }

  void bypassOtp() {
    final current = state.currentStop;
    if (current == null) return;

    final currentLedger = state.seatLedger ?? SeatLedger.empty(capacity: state.maxCapacity);
    SeatLedger updatedLedger = currentLedger;

    if (current.isPickup) {
      updatedLedger = _verificationEngine.boardPassenger(
        ledger: currentLedger,
        bookingId: current.passengerId,
        partySize: current.seats,
      );
    }

    emit(state.copyWith(
      isCurrentStopVerified: true,
      enteredOtp: _verificationEngine.cleanCode(current.verificationCode),
      otpFailedAttempts: 0,
      isStopLocked: false,
      clearOtpErrorMessage: true,
      seatLedger: updatedLedger,
    ));
  }

  void manualUnlockStop() {
    emit(state.copyWith(
      isStopLocked: false,
      otpFailedAttempts: 0,
      enteredOtp: '',
      clearOtpErrorMessage: true,
    ));
  }

  void confirmCurrentStop({bool bypassVerification = false}) {
    final current = state.currentStop;
    if (current == null) return;

    // Disallow boarding if unverified for pickup stops
    if (current.isPickup && !state.isCurrentStopVerified && !bypassVerification) {
      return;
    }

    final updatedStops = List<DriverStop>.from(state.stops);
    updatedStops[state.currentStopIndex] =
        current.copyWith(status: DriverStopStatus.completed);

    final nextIndex = state.currentStopIndex + 1;
    final updatedCabinSeats = List<CabinSeat>.from(state.cabinSeats);
    int newOccupancy = state.currentOccupancy;
    SeatLedger currentLedger = state.seatLedger ?? SeatLedger.empty(capacity: state.maxCapacity);

    if (current.isPickup) {
      // Allocate seats to passenger
      int seatsNeeded = current.seats;
      for (int i = 0; i < updatedCabinSeats.length; i++) {
        if (!updatedCabinSeats[i].isOccupied && seatsNeeded > 0) {
          updatedCabinSeats[i] = updatedCabinSeats[i].copyWith(
            passengerName: current.passengerName,
            passengerId: current.passengerId,
          );
          seatsNeeded--;
        }
      }
      newOccupancy = (state.currentOccupancy + current.seats)
          .clamp(0, state.maxCapacity);

      if (!state.isCurrentStopVerified && bypassVerification) {
        currentLedger = _verificationEngine.boardPassenger(
          ledger: currentLedger,
          bookingId: current.passengerId,
          partySize: current.seats,
        );
      }
    } else {
      // Dropoff passenger: free up their seats
      for (int i = 0; i < updatedCabinSeats.length; i++) {
        if (updatedCabinSeats[i].passengerId == current.passengerId ||
            updatedCabinSeats[i].passengerName == current.passengerName) {
          updatedCabinSeats[i] = updatedCabinSeats[i].copyWith(
            clearPassenger: true,
          );
        }
      }
      newOccupancy = (state.currentOccupancy - current.seats).clamp(0, state.maxCapacity);
      currentLedger = currentLedger.releaseOccupiedSeats(
        bookingId: current.passengerId,
        partySize: current.seats,
      );
    }

    final isNextPickup = nextIndex < updatedStops.length && updatedStops[nextIndex].isPickup;

    if (nextIndex < updatedStops.length) {
      updatedStops[nextIndex] =
          updatedStops[nextIndex].copyWith(status: DriverStopStatus.current);
      emit(state.copyWith(
        stops: updatedStops,
        currentStopIndex: nextIndex,
        cabinSeats: updatedCabinSeats,
        currentOccupancy: newOccupancy,
        enteredOtp: '',
        otpFailedAttempts: 0,
        isStopLocked: false,
        isCurrentStopVerified: !isNextPickup, // Dropoffs don't require pickup OTP
        clearOtpErrorMessage: true,
        seatLedger: currentLedger,
      ));
    } else {
      emit(state.copyWith(
        stops: updatedStops,
        currentStopIndex: nextIndex,
        shiftStatus: DriverShiftStatus.routeCompleted,
        cabinSeats: updatedCabinSeats,
        currentOccupancy: newOccupancy,
        enteredOtp: '',
        otpFailedAttempts: 0,
        isStopLocked: false,
        isCurrentStopVerified: true,
        clearOtpErrorMessage: true,
        seatLedger: currentLedger,
      ));
    }
  }

  void confirmPickup({bool bypassVerification = false}) {
    if (state.currentStop?.isPickup ?? false) {
      confirmCurrentStop(bypassVerification: bypassVerification);
    }
  }

  void confirmDropoff() {
    if (state.currentStop?.isDropoff ?? false) {
      confirmCurrentStop();
    }
  }

  void toggleShiftStatus() {
    final newStatus = state.shiftStatus == DriverShiftStatus.online
        ? DriverShiftStatus.offline
        : DriverShiftStatus.online;
    emit(state.copyWith(shiftStatus: newStatus));
  }

  void resetRoute() {
    emit(_buildInitialState(state.vehicle, null));
  }

  void receiveJoinProposal({
    required DriverStop pickupStop,
    required DriverStop dropoffStop,
  }) {
    emit(state.copyWith(
      pendingPickupStop: pickupStop,
      pendingDropoffStop: dropoffStop,
    ));
  }

  void approveJoinProposal() {
    final pStop = state.pendingPickupStop;
    final dStop = state.pendingDropoffStop;
    if (pStop == null || dStop == null) return;

    final updatedStops = List<DriverStop>.from(state.stops);
    // Insert new pickup before last dropoff
    final lastDropoffIndex = updatedStops.lastIndexWhere((s) => s.isDropoff);
    final insertPickupIndex = lastDropoffIndex != -1 ? lastDropoffIndex : updatedStops.length;
    updatedStops.insert(insertPickupIndex, pStop);
    updatedStops.add(dStop);

    emit(state.copyWith(
      stops: updatedStops,
      clearPendingPickupStop: true,
      clearPendingDropoffStop: true,
    ));
  }

  void rejectJoinProposal() {
    emit(state.copyWith(
      clearPendingPickupStop: true,
      clearPendingDropoffStop: true,
    ));
  }

  void cancelRider(String passengerId) {
    // Only pending stops are removed; completed ones remain frozen in history
    final updatedStops = state.stops.where((s) {
      if (s.passengerId == passengerId && s.status != DriverStopStatus.completed) {
        return false;
      }
      return true;
    }).toList();

    emit(state.copyWith(stops: updatedStops));
  }
}
