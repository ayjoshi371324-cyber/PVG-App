/// Detour Validator enforcing strict passenger detour limits (<= 15%).
class DetourValidator {
  final double maxDetourRatio; // default 0.15 = 15%

  const DetourValidator({this.maxDetourRatio = 0.15});

  /// Computes the percentage detour: `((sharedKm - soloKm) / soloKm) * 100`.
  double calculateDetourPercent(double soloKm, double sharedKm) {
    if (soloKm <= 0.0) return 0.0;
    final detour = ((sharedKm - soloKm) / soloKm) * 100.0;
    return detour < 0.0 ? 0.0 : double.parse(detour.toStringAsFixed(2));
  }

  /// Returns true if the shared distance satisfies the detour limit.
  bool isDetourValid(double soloKm, double sharedKm) {
    if (soloKm <= 0.0) return true;
    final ratio = (sharedKm - soloKm) / soloKm;
    // Allow slight floating point tolerance (1e-5)
    return ratio <= (maxDetourRatio + 1e-5);
  }
}
