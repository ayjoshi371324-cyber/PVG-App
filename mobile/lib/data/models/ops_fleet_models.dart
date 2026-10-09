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
  });

  final String id;
  final String name;
  final String licensePlate;
  final FleetVehicleStatus status;
  final PuneLocation currentLocation;
  final int currentOccupancy;
  final int maxCapacity;
  final int batteryPercentage;
  final String? assignedRouteName;

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
  });

  final double vktAlgorithmic;
  final double vktGreedy;
  final double detourAlgorithmic;
  final double detourGreedy;
  final double fareSavingsPercentAlgorithmic;
  final double fareSavingsPercentGreedy;

  double get vktSavingsPercent =>
      vktGreedy > 0 ? (((vktGreedy - vktAlgorithmic) / vktGreedy) * 100) : 0.0;

  BenchmarkMetrics copyWith({
    double? vktAlgorithmic,
    double? vktGreedy,
    double? detourAlgorithmic,
    double? detourGreedy,
    double? fareSavingsPercentAlgorithmic,
    double? fareSavingsPercentGreedy,
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
