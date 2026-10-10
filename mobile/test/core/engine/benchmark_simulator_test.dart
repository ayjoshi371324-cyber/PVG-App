import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/benchmark_simulator.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';

void main() {
  group('BenchmarkSimulator & GreedyBaseline Tests', () {
    late BenchmarkSimulator simulator;

    setUp(() {
      simulator = BenchmarkSimulator();
    });

    test('runs truthful side-by-side benchmark on identical requests and seed', () {
      final vehicles = [
        const FleetVehicle(
          id: 'EV-01',
          name: 'Tata Tigor EV',
          licensePlate: 'MH 12 RN 4001',
          status: FleetVehicleStatus.idle,
          currentLocation: PuneLandmarks.swargate,
          currentOccupancy: 0,
          maxCapacity: 4,
          onboardSeats: 0,
          reservedSeats: 0,
          heldSeats: 0,
        ),
        const FleetVehicle(
          id: 'EV-02',
          name: 'Tata Tigor EV',
          licensePlate: 'MH 12 RN 4002',
          status: FleetVehicleStatus.pickingUp,
          currentLocation: PuneLandmarks.kothrud,
          currentOccupancy: 1,
          maxCapacity: 4,
          onboardSeats: 1,
          reservedSeats: 0,
          heldSeats: 0,
        ),
        const FleetVehicle(
          id: 'EV-03',
          name: 'Tata Nexon EV',
          licensePlate: 'MH 12 RN 5100',
          status: FleetVehicleStatus.inPool,
          currentLocation: PuneLandmarks.hinjawadiPhase1,
          currentOccupancy: 2,
          maxCapacity: 4,
          onboardSeats: 2,
          reservedSeats: 1,
          heldSeats: 0,
        ),
      ];

      final requests = [
        SyntheticDemandRequest(
          id: 'req-1',
          passengerName: 'Passenger 1',
          pickup: PuneLandmarks.kothrud,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          partySize: 1,
          requestedAt: DateTime(2026, 1, 1, 10, 0),
        ),
        SyntheticDemandRequest(
          id: 'req-2',
          passengerName: 'Passenger 2',
          pickup: PuneLandmarks.shivajiNagar,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          partySize: 1,
          requestedAt: DateTime(2026, 1, 1, 10, 1),
        ),
        SyntheticDemandRequest(
          id: 'req-3',
          passengerName: 'Passenger 3',
          pickup: PuneLandmarks.swargate,
          dropoff: PuneLandmarks.vimanNagar,
          partySize: 2,
          requestedAt: DateTime(2026, 1, 1, 10, 2),
        ),
      ];

      final result = simulator.runBenchmark(
        requests: requests,
        vehicles: vehicles,
        seed: 42,
      );

      // Verify truthful side-by-side comparison
      expect(result.testedVehiclesCount, equals(3));
      expect(result.testedPassengersCount, equals(3));

      // Algorithmic pooling should save VKT compared to greedy baseline
      expect(result.vktAlgorithmic, lessThan(result.vktGreedy));
      expect(result.vktSavingsKm, greaterThan(0));
      expect(result.vktSavingsPercent, greaterThan(0));

      // Algorithmic detour should satisfy strict <= 15% guarantee
      expect(result.detourAlgorithmic, lessThanOrEqualTo(15.0));
      expect(result.p95DetourAlgorithmic, lessThanOrEqualTo(15.0));

      // Greedy detour is higher or violates 15%
      expect(result.detourGreedy, greaterThan(result.detourAlgorithmic));

      // Service rate comparison
      expect(result.serviceRateAlgorithmic, greaterThanOrEqualTo(result.serviceRateGreedy));
    });
  });
}
