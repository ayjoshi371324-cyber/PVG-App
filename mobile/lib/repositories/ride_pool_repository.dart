/// Base contract for RidePool repositories supporting Dual Mode (Live backend vs Offline Simulation)
abstract class RidePoolRepository {
  /// Whether the repository is running in simulated offline mode
  bool get isSimulated;
}
