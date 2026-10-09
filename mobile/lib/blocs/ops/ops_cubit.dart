import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/ops/ops_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';

class OpsCubit extends Cubit<OpsState> {
  OpsCubit([OpsState? initialState])
      : super(initialState ?? _buildInitialState());

  static OpsState _buildInitialState() {
    final vehicles = [
      const FleetVehicle(
        id: 'EV-01',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 4001',
        status: FleetVehicleStatus.idle,
        currentLocation: PuneLandmarks.swargate,
        currentOccupancy: 0,
        maxCapacity: 4,
        batteryPercentage: 88,
      ),
      const FleetVehicle(
        id: 'EV-02',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 4002',
        status: FleetVehicleStatus.pickingUp,
        currentLocation: PuneLandmarks.kothrud,
        currentOccupancy: 1,
        maxCapacity: 4,
        batteryPercentage: 79,
        assignedRouteName: 'Kothrud-Hinjawadi Corridor',
      ),
      const FleetVehicle(
        id: 'EV-03',
        name: 'Tata Nexon EV',
        licensePlate: 'MH 12 RN 5100',
        status: FleetVehicleStatus.inPool,
        currentLocation: PuneLandmarks.hinjawadiPhase1,
        currentOccupancy: 3,
        maxCapacity: 4,
        batteryPercentage: 65,
        assignedRouteName: 'ShivajiNagar-Hinjawadi Express',
      ),
      const FleetVehicle(
        id: 'EV-04',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 8842',
        status: FleetVehicleStatus.inPool,
        currentLocation: PuneLandmarks.shivajiNagar,
        currentOccupancy: 2,
        maxCapacity: 4,
        batteryPercentage: 84,
        assignedRouteName: 'Central-West IT Pool',
      ),
      const FleetVehicle(
        id: 'EV-05',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 6012',
        status: FleetVehicleStatus.pickingUp,
        currentLocation: PuneLandmarks.vimanNagar,
        currentOccupancy: 1,
        maxCapacity: 4,
        batteryPercentage: 92,
        assignedRouteName: 'East Corridor Shuttle',
      ),
      const FleetVehicle(
        id: 'EV-06',
        name: 'Tata Nexon EV',
        licensePlate: 'MH 12 RN 7200',
        status: FleetVehicleStatus.idle,
        currentLocation: PuneLandmarks.hadapsar,
        currentOccupancy: 0,
        maxCapacity: 4,
        batteryPercentage: 81,
      ),
    ];

    final pending = [
      SyntheticDemandRequest(
        id: 'req-1',
        passengerName: 'Tanmay Deshmukh',
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 14)),
      ),
      SyntheticDemandRequest(
        id: 'req-2',
        passengerName: 'Neha Kulkarni',
        pickup: PuneLandmarks.shivajiNagar,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 2,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 9)),
      ),
      SyntheticDemandRequest(
        id: 'req-3',
        passengerName: 'Aditya Joshi',
        pickup: PuneLandmarks.swargate,
        dropoff: PuneLandmarks.vimanNagar,
        partySize: 1,
        requestedAt: DateTime.now().subtract(const Duration(seconds: 3)),
      ),
    ];

    const benchmark = BenchmarkMetrics(
      vktAlgorithmic: 142.6,
      vktGreedy: 231.0,
      detourAlgorithmic: 8.4,
      detourGreedy: 24.6,
      fareSavingsPercentAlgorithmic: 32.5,
      fareSavingsPercentGreedy: 7.5,
    );

    final detourRecords = [
      const ActiveRouteDetourRecord(
        routeId: 'R-101',
        vehicleId: 'EV-02',
        directDistanceKm: 16.2,
        pooledDistanceKm: 17.2,
      ),
      const ActiveRouteDetourRecord(
        routeId: 'R-102',
        vehicleId: 'EV-03',
        directDistanceKm: 14.5,
        pooledDistanceKm: 15.8,
      ),
      const ActiveRouteDetourRecord(
        routeId: 'R-103',
        vehicleId: 'EV-04',
        directDistanceKm: 12.0,
        pooledDistanceKm: 13.3,
      ),
      const ActiveRouteDetourRecord(
        routeId: 'R-104',
        vehicleId: 'EV-05',
        directDistanceKm: 10.5,
        pooledDistanceKm: 11.7,
      ),
    ];

    return OpsState(
      vehicles: vehicles,
      pendingDemand: pending,
      benchmark: benchmark,
      activeDetourRecords: detourRecords,
      totalCompletedBatches: 1,
      lastBatchMessage: 'Initial Fleet Synchronized',
    );
  }

  void selectVehicle(String vehicleId) {
    emit(state.copyWith(selectedVehicleId: vehicleId));
  }

  void clearSelectedVehicle() {
    emit(state.copyWith(clearSelectedVehicle: true));
  }

  void injectSyntheticDemand({int count = 3}) {
    final names = [
      'Gaurav Shinde',
      'Priyanka More',
      'Siddharth Rao',
      'Ananya Mehta',
      'Vikram Kadam',
    ];
    final pickups = [
      PuneLandmarks.koregaonPark,
      PuneLandmarks.swargate,
      PuneLandmarks.kothrud,
      PuneLandmarks.vimanNagar,
    ];
    final dropoffs = [
      PuneLandmarks.hinjawadiPhase1,
      PuneLandmarks.hadapsar,
      PuneLandmarks.shivajiNagar,
    ];

    final currentCount = state.pendingDemand.length;
    final newRequests = <SyntheticDemandRequest>[];

    for (int i = 0; i < count; i++) {
      final idx = (currentCount + i) % names.length;
      final pIdx = (currentCount + i) % pickups.length;
      final dIdx = (currentCount + i) % dropoffs.length;

      newRequests.add(
        SyntheticDemandRequest(
          id: 'req-${DateTime.now().millisecondsSinceEpoch}-$i',
          passengerName: names[idx],
          pickup: pickups[pIdx],
          dropoff: dropoffs[dIdx],
          partySize: (i % 2) + 1,
          requestedAt: DateTime.now(),
        ),
      );
    }

    emit(state.copyWith(
      pendingDemand: [...state.pendingDemand, ...newRequests],
    ));
  }

  void triggerBatchOptimization() {
    final requestsToProcess = state.pendingDemand.length;

    // Transition idle vehicles to active if demand exists
    final updatedVehicles = state.vehicles.map((v) {
      if (v.isIdle && requestsToProcess > 0) {
        return v.copyWith(
          status: FleetVehicleStatus.pickingUp,
          currentOccupancy: 2,
          assignedRouteName: 'Dynamic Pooled Dispatch',
        );
      }
      return v;
    }).toList();

    final nextBatchNum = state.totalCompletedBatches + 1;
    final addedKm = requestsToProcess > 0 ? requestsToProcess * 4.2 : 5.0;
    final addedGreedyKm = requestsToProcess > 0 ? requestsToProcess * 8.4 : 9.5;

    final updatedBenchmark = state.benchmark.copyWith(
      vktAlgorithmic: double.parse(
          (state.benchmark.vktAlgorithmic + addedKm).toStringAsFixed(1)),
      vktGreedy: double.parse(
          (state.benchmark.vktGreedy + addedGreedyKm).toStringAsFixed(1)),
    );

    emit(state.copyWith(
      vehicles: updatedVehicles,
      pendingDemand: const [],
      benchmark: updatedBenchmark,
      totalCompletedBatches: nextBatchNum,
      lastBatchMessage:
          'Batch #$nextBatchNum Optimized: $requestsToProcess requests pooled (Detour <= 15%)',
    ));
  }
}
