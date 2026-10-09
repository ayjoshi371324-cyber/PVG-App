import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';

class OpsState extends Equatable {
  const OpsState({
    required this.vehicles,
    required this.pendingDemand,
    required this.benchmark,
    required this.activeDetourRecords,
    this.selectedVehicleId,
    this.isBatchOptimizing = false,
    this.totalCompletedBatches = 1,
    this.lastBatchMessage,
  });

  final List<FleetVehicle> vehicles;
  final List<SyntheticDemandRequest> pendingDemand;
  final BenchmarkMetrics benchmark;
  final List<ActiveRouteDetourRecord> activeDetourRecords;
  final String? selectedVehicleId;
  final bool isBatchOptimizing;
  final int totalCompletedBatches;
  final String? lastBatchMessage;

  int get totalFleetCount => vehicles.length;
  int get activeFleetCount => vehicles.where((v) => !v.isIdle).length;
  int get idleFleetCount => vehicles.where((v) => v.isIdle).length;
  int get pickingUpFleetCount =>
      vehicles.where((v) => v.isPickingUp).length;
  int get inPoolFleetCount => vehicles.where((v) => v.isInPool).length;

  FleetVehicle? get selectedVehicle {
    if (selectedVehicleId == null) return null;
    try {
      return vehicles.firstWhere((v) => v.id == selectedVehicleId);
    } catch (_) {
      return null;
    }
  }

  double get detourComplianceRate {
    if (activeDetourRecords.isEmpty) return 100.0;
    final compliantCount =
        activeDetourRecords.where((r) => r.isCompliant).length;
    return (compliantCount / activeDetourRecords.length) * 100.0;
  }

  double get maxActiveDetourPercent {
    if (activeDetourRecords.isEmpty) return 0.0;
    return activeDetourRecords
        .map((r) => r.detourPercent)
        .fold<double>(0.0, max);
  }

  OpsState copyWith({
    List<FleetVehicle>? vehicles,
    List<SyntheticDemandRequest>? pendingDemand,
    BenchmarkMetrics? benchmark,
    List<ActiveRouteDetourRecord>? activeDetourRecords,
    String? selectedVehicleId,
    bool clearSelectedVehicle = false,
    bool? isBatchOptimizing,
    int? totalCompletedBatches,
    String? lastBatchMessage,
  }) {
    return OpsState(
      vehicles: vehicles ?? this.vehicles,
      pendingDemand: pendingDemand ?? this.pendingDemand,
      benchmark: benchmark ?? this.benchmark,
      activeDetourRecords: activeDetourRecords ?? this.activeDetourRecords,
      selectedVehicleId: clearSelectedVehicle
          ? null
          : (selectedVehicleId ?? this.selectedVehicleId),
      isBatchOptimizing: isBatchOptimizing ?? this.isBatchOptimizing,
      totalCompletedBatches:
          totalCompletedBatches ?? this.totalCompletedBatches,
      lastBatchMessage: lastBatchMessage ?? this.lastBatchMessage,
    );
  }

  @override
  List<Object?> get props => [
        vehicles,
        pendingDemand,
        benchmark,
        activeDetourRecords,
        selectedVehicleId,
        isBatchOptimizing,
        totalCompletedBatches,
        lastBatchMessage,
      ];
}
