import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class DriverVehicle extends Equatable {
  const DriverVehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    this.maxSeats = 4,
    this.batteryPercentage = 84,
  });

  final String id;
  final String name;
  final String licensePlate;
  final int maxSeats;
  final int batteryPercentage;

  @override
  List<Object?> get props => [
        id,
        name,
        licensePlate,
        maxSeats,
        batteryPercentage,
      ];
}

enum DriverStopType {
  pickup,
  dropoff,
}

enum DriverStopStatus {
  pending,
  current,
  completed,
}

class DriverStop extends Equatable {
  const DriverStop({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.stopType,
    required this.location,
    required this.seats,
    required this.verificationCode,
    this.etaMinutes = 3,
    this.distanceKm = 0.8,
    this.status = DriverStopStatus.pending,
  });

  final String id;
  final String passengerId;
  final String passengerName;
  final DriverStopType stopType;
  final PuneLocation location;
  final int seats;
  final String verificationCode;
  final int etaMinutes;
  final double distanceKm;
  final DriverStopStatus status;

  bool get isPickup => stopType == DriverStopType.pickup;
  bool get isDropoff => stopType == DriverStopType.dropoff;
  bool get isCurrent => status == DriverStopStatus.current;
  bool get isCompleted => status == DriverStopStatus.completed;

  String get actionLabel => isPickup ? 'Passenger Picked Up' : 'Passenger Dropped Off';

  DriverStop copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    DriverStopType? stopType,
    PuneLocation? location,
    int? seats,
    String? verificationCode,
    int? etaMinutes,
    double? distanceKm,
    DriverStopStatus? status,
  }) {
    return DriverStop(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      stopType: stopType ?? this.stopType,
      location: location ?? this.location,
      seats: seats ?? this.seats,
      verificationCode: verificationCode ?? this.verificationCode,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        passengerId,
        passengerName,
        stopType,
        location,
        seats,
        verificationCode,
        etaMinutes,
        distanceKm,
        status,
      ];
}

class CabinSeat extends Equatable {
  const CabinSeat({
    required this.seatIndex,
    required this.label,
    this.passengerName,
    this.passengerId,
  });

  final int seatIndex;
  final String label;
  final String? passengerName;
  final String? passengerId;

  bool get isOccupied => passengerName != null && passengerName!.isNotEmpty;

  CabinSeat copyWith({
    int? seatIndex,
    String? label,
    String? passengerName,
    String? passengerId,
    bool clearPassenger = false,
  }) {
    return CabinSeat(
      seatIndex: seatIndex ?? this.seatIndex,
      label: label ?? this.label,
      passengerName: clearPassenger ? null : (passengerName ?? this.passengerName),
      passengerId: clearPassenger ? null : (passengerId ?? this.passengerId),
    );
  }

  @override
  List<Object?> get props => [
        seatIndex,
        label,
        passengerName,
        passengerId,
      ];
}
