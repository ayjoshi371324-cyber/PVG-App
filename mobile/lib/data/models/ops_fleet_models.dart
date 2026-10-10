import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

enum FleetVehicleStatus {
  idle,
  pickingUp,
  inPool,
}

class FleetVehicle extends Equatable {
  const FleetVehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.status,
    required this.currentLocation,
    this.currentOccupancy = 0,
    this.maxCapacity = 4,
    this.batteryPercentage = 80,
    this.assignedRouteName,
    int? onboardSeats,
    int? reservedSeats,
    int? heldSeats,
  })  : onboardSeats = onboardSeats ?? currentOccupancy,
        reservedSeats = reservedSeats ?? 0,
        heldSeats = heldSeats ?? 0;

  final String id;
  final String name;
  final String licensePlate;
  final FleetVehicleStatus status;
  final PuneLocation currentLocation;
  final int currentOccupancy;
  final int maxCapacity;
  final int batteryPercentage;
  final String? assignedRouteName;

  /// Cabin Seat Breakdown
  final int onboardSeats;
  final int reservedSeats;
  final int heldSeats;

  int get freeSeats => (maxCapacity - onboardSeats - reservedSeats - heldSeats).clamp(0, maxCapacity);

  bool get isIdle => status == FleetVehicleStatus.idle;
  bool get isPickingUp => status == FleetVehicleStatus.pickingUp;
  bool get isInPool => status == FleetVehicleStatus.inPool;

  String get statusLabel {
    switch (status) {
      case FleetVehicleStatus.idle:
        return 'Idle';
      case FleetVehicleStatus.pickingUp:
        return 'Picking Up';
      case FleetVehicleStatus.inPool:
        return 'In Pool';
    }
  }

  FleetVehicle copyWith({
    String? id,
    String? name,
    String? licensePlate,
    FleetVehicleStatus? status,
    PuneLocation? currentLocation,
    int? currentOccupancy,
    int? maxCapacity,
    int? batteryPercentage,
    String? assignedRouteName,
    int? onboardSeats,
    int? reservedSeats,
    int? heldSeats,
  }) {
    return FleetVehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      assignedRouteName: assignedRouteName ?? this.assignedRouteName,
      onboardSeats: onboardSeats ?? this.onboardSeats,
      reservedSeats: reservedSeats ?? this.reservedSeats,
      heldSeats: heldSeats ?? this.heldSeats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        licensePlate,
        status,
        currentLocation,
        currentOccupancy,
        maxCapacity,
        batteryPercentage,
        assignedRouteName,
        onboardSeats,
        reservedSeats,
        heldSeats,
      ];
}

class SyntheticDemandRequest extends Equatable {
  const SyntheticDemandRequest({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    this.partySize = 1,
    required this.requestedAt,
  });

  final String id;
  final String passengerName;
  final PuneLocation pickup;
  final PuneLocation dropoff;
  final int partySize;
  final DateTime requestedAt;

  @override
  List<Object?> get props => [
        id,
        passengerName,
        pickup,
        dropoff,
        partySize,
        requestedAt,
      ];
}

class BenchmarkMetrics extends Equatable {
  const BenchmarkMetrics({
    required this.vktAlgorithmic,
    required this.vktGreedy,
    required this.detourAlgorithmic,
    required this.detourGreedy,
    required this.fareSavingsPercentAlgorithmic,
    required this.fareSavingsPercentGreedy,
    this.serviceRateAlgorithmic = 100.0,
    this.serviceRateGreedy = 82.0,
    this.p95DetourAlgorithmic = 12.5,
    this.p95DetourGreedy = 29.5,
    this.testedVehiclesCount = 6,
    this.testedPassengersCount = 12,
    this.seed,
  });

  final double vktAlgorithmic;
  final double vktGreedy;
  final double detourAlgorithmic;
  final double detourGreedy;
  final double fareSavingsPercentAlgorithmic;
  final double fareSavingsPercentGreedy;
  final double serviceRateAlgorithmic;
  final double serviceRateGreedy;
  final double p95DetourAlgorithmic;
  final double p95DetourGreedy;
  final int testedVehiclesCount;
  final int testedPassengersCount;
  final int? seed;

  double get vktSavingsPercent =>
      vktGreedy > 0 ? (((vktGreedy - vktAlgorithmic) / vktGreedy) * 100) : 0.0;

  double get vktSavingsKm =>
      (vktGreedy - vktAlgorithmic > 0) ? (vktGreedy - vktAlgorithmic) : 0.0;

  BenchmarkMetrics copyWith({
    double? vktAlgorithmic,
    double? vktGreedy,
    double? detourAlgorithmic,
    double? detourGreedy,
    double? fareSavingsPercentAlgorithmic,
    double? fareSavingsPercentGreedy,
    double? serviceRateAlgorithmic,
    double? serviceRateGreedy,
    double? p95DetourAlgorithmic,
    double? p95DetourGreedy,
    int? testedVehiclesCount,
    int? testedPassengersCount,
    int? seed,
  }) {
    return BenchmarkMetrics(
      vktAlgorithmic: vktAlgorithmic ?? this.vktAlgorithmic,
      vktGreedy: vktGreedy ?? this.vktGreedy,
      detourAlgorithmic: detourAlgorithmic ?? this.detourAlgorithmic,
      detourGreedy: detourGreedy ?? this.detourGreedy,
      fareSavingsPercentAlgorithmic:
          fareSavingsPercentAlgorithmic ?? this.fareSavingsPercentAlgorithmic,
      fareSavingsPercentGreedy:
          fareSavingsPercentGreedy ?? this.fareSavingsPercentGreedy,
      serviceRateAlgorithmic:
          serviceRateAlgorithmic ?? this.serviceRateAlgorithmic,
      serviceRateGreedy: serviceRateGreedy ?? this.serviceRateGreedy,
      p95DetourAlgorithmic:
          p95DetourAlgorithmic ?? this.p95DetourAlgorithmic,
      p95DetourGreedy: p95DetourGreedy ?? this.p95DetourGreedy,
      testedVehiclesCount: testedVehiclesCount ?? this.testedVehiclesCount,
      testedPassengersCount:
          testedPassengersCount ?? this.testedPassengersCount,
      seed: seed ?? this.seed,
    );
  }

  @override
  List<Object?> get props => [
        vktAlgorithmic,
        vktGreedy,
        detourAlgorithmic,
        detourGreedy,
        fareSavingsPercentAlgorithmic,
        fareSavingsPercentGreedy,
        serviceRateAlgorithmic,
        serviceRateGreedy,
        p95DetourAlgorithmic,
        p95DetourGreedy,
        testedVehiclesCount,
        testedPassengersCount,
        seed,
      ];
}

class ActiveRouteDetourRecord extends Equatable {
  const ActiveRouteDetourRecord({
    required this.routeId,
    required this.vehicleId,
    required this.directDistanceKm,
    required this.pooledDistanceKm,
  });

  final String routeId;
  final String vehicleId;
  final double directDistanceKm;
  final double pooledDistanceKm;

  double get detourPercent => directDistanceKm > 0
      ? (((pooledDistanceKm - directDistanceKm) / directDistanceKm) * 100)
      : 0.0;

  bool get isCompliant => detourPercent <= 15.0;

  @override
  List<Object?> get props => [
        routeId,
        vehicleId,
        directDistanceKm,
        pooledDistanceKm,
      ];
}
