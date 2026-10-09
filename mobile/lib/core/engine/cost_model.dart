/// Deterministic Cost Model for RidePool AI.
///
/// Implements standard pricing:
/// `trip_cost = base_fee + (rate_per_km * distance_km)`
class CostModel {
  final double baseFee;
  final double ratePerKm;

  const CostModel({
    this.baseFee = 20.0,
    this.ratePerKm = 10.0,
  });

  /// Computes the monetary cost for a given distance in kilometers.
  double tripCost(double distanceKm, {double multiplier = 1.0}) {
    if (distanceKm <= 0.0) return 0.0;
    final cost = (baseFee + (ratePerKm * distanceKm)) * multiplier;
    return double.parse(cost.toStringAsFixed(2));
  }
}
