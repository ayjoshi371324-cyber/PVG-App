import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/ops/ops_cubit.dart';

void main() {
  group('OpsCubit Unit Tests', () {
    late OpsCubit opsCubit;

    setUp(() {
      opsCubit = OpsCubit();
    });

    tearDown(() {
      opsCubit.close();
    });

    test('initializes with fleet vehicles, benchmarks, and 100% detour compliance', () {
      final state = opsCubit.state;
      expect(state.totalFleetCount, equals(6));
      expect(state.idleFleetCount, greaterThan(0));
      expect(state.inPoolFleetCount, greaterThan(0));
      expect(state.pickingUpFleetCount, greaterThan(0));
      expect(state.activeFleetCount, greaterThan(0));

      // Detour guarantee: 100% compliant with <= 15%
      expect(state.detourComplianceRate, equals(100.0));
      expect(state.maxActiveDetourPercent, lessThanOrEqualTo(15.0));

      // Benchmark metrics verification
      expect(state.benchmark.vktAlgorithmic, lessThan(state.benchmark.vktGreedy));
      expect(state.benchmark.vktSavingsPercent, greaterThan(25.0));
      expect(state.benchmark.detourAlgorithmic, lessThan(state.benchmark.detourGreedy));
      expect(state.benchmark.fareSavingsPercentAlgorithmic, greaterThan(state.benchmark.fareSavingsPercentGreedy));
    });

    test('injectSyntheticDemand adds new passenger requests to the pending queue', () {
      expect(opsCubit.state.pendingDemand.length, equals(3));

      opsCubit.injectSyntheticDemand(count: 3);

      expect(opsCubit.state.pendingDemand.length, equals(6));
      expect(opsCubit.state.pendingDemand.last.passengerName, isNotEmpty);
    });

    test('selectVehicle updates selected vehicle state', () {
      expect(opsCubit.state.selectedVehicle, isNull);

      opsCubit.selectVehicle('EV-02');
      expect(opsCubit.state.selectedVehicleId, equals('EV-02'));
      expect(opsCubit.state.selectedVehicle?.id, equals('EV-02'));

      opsCubit.clearSelectedVehicle();
      expect(opsCubit.state.selectedVehicle, isNull);
    });

    test('triggerBatchOptimization processes pending demand and updates fleet and metrics', () {
      opsCubit.injectSyntheticDemand(count: 2);
      final initialBatches = opsCubit.state.totalCompletedBatches;
      final initialVktAlgorithmic = opsCubit.state.benchmark.vktAlgorithmic;

      opsCubit.triggerBatchOptimization();

      final state = opsCubit.state;
      expect(state.totalCompletedBatches, equals(initialBatches + 1));
      expect(state.pendingDemand.isEmpty, isTrue);
      expect(state.lastBatchMessage, isNotNull);
      expect(state.lastBatchMessage, contains('Optimized'));

      // Detour compliance remains 100% <= 15%
      expect(state.detourComplianceRate, equals(100.0));
      expect(state.maxActiveDetourPercent, lessThanOrEqualTo(15.0));
      expect(state.benchmark.vktAlgorithmic, greaterThan(initialVktAlgorithmic));
    });
  });
}
