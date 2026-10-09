import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';

enum DriverShiftStatus {
  online,
  offline,
  routeCompleted,
}

class DriverState extends Equatable {
  const DriverState({
    required this.vehicle,
    required this.stops,
    this.currentStopIndex = 0,
    this.shiftStatus = DriverShiftStatus.online,
    this.cabinSeats = const [],
    this.currentOccupancy = 0,
    this.pendingPickupStop,
    this.pendingDropoffStop,
  });

  final DriverVehicle vehicle;
  final List<DriverStop> stops;
  final int currentStopIndex;
  final DriverShiftStatus shiftStatus;
  final List<CabinSeat> cabinSeats;
  final int currentOccupancy;
  final DriverStop? pendingPickupStop;
  final DriverStop? pendingDropoffStop;

  DriverStop? get currentStop =>
      (currentStopIndex >= 0 && currentStopIndex < stops.length)
          ? stops[currentStopIndex]
          : null;

  bool get isRouteCompleted =>
      currentStopIndex >= stops.length ||
      shiftStatus == DriverShiftStatus.routeCompleted;

  int get completedStopsCount =>
      stops.where((s) => s.status == DriverStopStatus.completed).length;

  int get remainingStopsCount =>
      stops.where((s) => s.status != DriverStopStatus.completed).length;

  int get maxCapacity => vehicle.maxSeats;

  double get occupancyRatio =>
      maxCapacity > 0 ? (currentOccupancy / maxCapacity).clamp(0.0, 1.0) : 0.0;

  bool get isCabinFull => currentOccupancy >= maxCapacity;

  DriverState copyWith({
    DriverVehicle? vehicle,
    List<DriverStop>? stops,
    int? currentStopIndex,
    DriverShiftStatus? shiftStatus,
    List<CabinSeat>? cabinSeats,
    int? currentOccupancy,
    DriverStop? pendingPickupStop,
    bool clearPendingPickupStop = false,
    DriverStop? pendingDropoffStop,
    bool clearPendingDropoffStop = false,
  }) {
    return DriverState(
      vehicle: vehicle ?? this.vehicle,
      stops: stops ?? this.stops,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      shiftStatus: shiftStatus ?? this.shiftStatus,
      cabinSeats: cabinSeats ?? this.cabinSeats,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      pendingPickupStop: clearPendingPickupStop
          ? null
          : (pendingPickupStop ?? this.pendingPickupStop),
      pendingDropoffStop: clearPendingDropoffStop
          ? null
          : (pendingDropoffStop ?? this.pendingDropoffStop),
    );
  }

  @override
  List<Object?> get props => [
        vehicle,
        stops,
        currentStopIndex,
        shiftStatus,
        cabinSeats,
        currentOccupancy,
        pendingPickupStop,
        pendingDropoffStop,
      ];
}
