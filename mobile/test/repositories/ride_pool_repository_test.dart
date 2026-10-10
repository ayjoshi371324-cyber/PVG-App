import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/repositories/ride_pool_repository.dart';
import 'package:ridepool_app/services/auth_service.dart';

void main() {
  group('Dual-Mode RidePoolRepository Tests', () {
    late DualModeRidePoolRepository repository;

    setUp(() {
      repository = DualModeRidePoolRepository();
    });

    test('initializes in Offline Simulation mode by default', () {
      expect(repository.isSimulated, isTrue);
      expect(repository.mode, equals(RepositoryMode.offlineSimulation));
    });

    test('seamlessly toggles between Live Backend and Offline Simulation', () {
      repository.setMode(RepositoryMode.liveBackend);
      expect(repository.isSimulated, isFalse);
      expect(repository.mode, equals(RepositoryMode.liveBackend));

      repository.setMode(RepositoryMode.offlineSimulation);
      expect(repository.isSimulated, isTrue);
      expect(repository.mode, equals(RepositoryMode.offlineSimulation));
    });

    test('offline simulation provides instant demo login and fleet data', () async {
      final response = await repository.login(
        MockAuthService.demoPassenger.email,
        'password123',
      );
      expect(response.user.email, equals(MockAuthService.demoPassenger.email));
      expect(response.user.role, equals(UserRole.passenger));

      final fleet = await repository.getFleetVehicles();
      expect(fleet.length, greaterThanOrEqualTo(6));
      expect(fleet.first.onboardSeats, isNotNull);
      expect(fleet.first.freeSeats, isNotNull);
    });

    test('offline simulation computes truthful benchmark analytics', () async {
      final benchmark = await repository.fetchBenchmark(seed: 42);
      expect(benchmark.vktAlgorithmic, lessThan(benchmark.vktGreedy));
      expect(benchmark.detourAlgorithmic, lessThanOrEqualTo(15.0));
      expect(benchmark.p95DetourAlgorithmic, lessThanOrEqualTo(15.0));
      expect(benchmark.vktSavingsKm, greaterThan(0));
    });
  });
}
