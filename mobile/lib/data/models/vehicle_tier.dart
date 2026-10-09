import 'package:ridepool_app/core/engine/cost_model.dart';

/// Supported vehicle tiers for RidePool operations in Pune corridor.
///
/// Multipliers and seat capacities follow Ticket 02 specifications:
/// - Auto: 3 seats, 0.8× base multiplier
/// - Car: 4 seats, 1.0× multiplier
/// - Car XL: 6 seats, 1.4× multiplier
enum VehicleTier {
  auto(
    id: 'auto',
    displayName: 'Auto',
    capacity: 3,
    rateMultiplier: 0.8,
    description: '3 seats • Fast urban corridor navigation',
  ),
  car(
    id: 'car',
    displayName: 'Car',
    capacity: 4,
    rateMultiplier: 1.0,
    description: '4 seats • Balanced comfort & economy',
  ),
  carXl(
    id: 'car_xl',
    displayName: 'Car XL',
    capacity: 6,
    rateMultiplier: 1.4,
    description: '6 seats • Spacious premium group travel',
  );

  const VehicleTier({
    required this.id,
    required this.displayName,
    required this.capacity,
    required this.rateMultiplier,
    required this.description,
  });

  final String id;
  final String displayName;
  final int capacity;
  final double rateMultiplier;
  final String description;

  /// Returns true if this vehicle tier can accommodate the requested [partySize].
  bool canAccommodatePartySize(int partySize) {
    return partySize > 0 && partySize <= capacity;
  }

  /// Returns explanatory helper text if the requested [partySize] exceeds tier capacity,
  /// or null if the party size is within capacity.
  String? disabledReason(int partySize) {
    if (partySize > capacity) {
      return 'Max $capacity seats (party size: $partySize)';
    }
    return null;
  }

  /// Calculates estimated solo fare using the deterministic [CostModel]
  /// scaled by this tier's [rateMultiplier].
  double calculateEstimatedFare(
    double distanceKm, {
    CostModel costModel = const CostModel(),
  }) {
    return costModel.tripCost(distanceKm, multiplier: rateMultiplier);
  }

  /// Parses tier identifier with fallback to [VehicleTier.car].
  static VehicleTier fromId(String id) {
    return VehicleTier.values.firstWhere(
      (tier) => tier.id == id,
      orElse: () => VehicleTier.car,
    );
  }
}
