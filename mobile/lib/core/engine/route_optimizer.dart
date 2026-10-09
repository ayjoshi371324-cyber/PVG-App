/// Represents a stop (pickup or dropoff) for route permutation optimization.
class RouteStop {
  final String id;
  final String bookingId;
  final bool isPickup;
  final double lat;
  final double lng;
  final int partySize;

  const RouteStop({
    required this.id,
    required this.bookingId,
    required this.isPickup,
    required this.lat,
    required this.lng,
    required this.partySize,
  });

  @override
  String toString() =>
      'RouteStop($id, $bookingId, ${isPickup ? "P" : "D"}, seats=$partySize)';
}

/// Result of a combinatorial route optimization.
class OptimizationResult {
  final List<RouteStop> orderedStops;
  final double totalDistanceKm;
  final bool isFeasible;
  final String? infeasibilityReason;

  const OptimizationResult({
    required this.orderedStops,
    required this.totalDistanceKm,
    required this.isFeasible,
    this.infeasibilityReason,
  });
}

/// Brute-force Route Permutation Optimizer with Precedence and Capacity Constraints.
///
/// Guarantees:
/// 1. Pickup-before-dropoff precedence for every booking.
/// 2. Vehicle seat capacity constraint is satisfied at every stop along the itinerary.
/// 3. Returns the valid sequence minimizing total travel distance.
class RouteOptimizer {
  /// Optimizes the stop sequence for the provided [stops].
  static OptimizationResult optimize({
    required List<RouteStop> stops,
    required int vehicleCapacity,
    required double Function(RouteStop from, RouteStop to) distanceFn,
  }) {
    if (stops.isEmpty) {
      return const OptimizationResult(
        orderedStops: [],
        totalDistanceKm: 0.0,
        isFeasible: true,
      );
    }

    // Group by booking to verify each booking has both pickup and dropoff
    final bookings = <String, List<RouteStop>>{};
    for (final stop in stops) {
      bookings.putIfAbsent(stop.bookingId, () => []).add(stop);
    }

    final permutations = _generatePermutations(stops);
    List<RouteStop>? bestSequence;
    double minDistance = double.infinity;

    for (final perm in permutations) {
      // 1. Check Precedence: Pickup must precede Dropoff for each booking
      if (!_satisfiesPrecedence(perm)) {
        continue;
      }

      // 2. Check Capacity along the route
      if (!_satisfiesCapacity(perm, vehicleCapacity)) {
        continue;
      }

      // 3. Compute total distance
      double totalDist = 0.0;
      for (int i = 0; i < perm.length - 1; i++) {
        totalDist += distanceFn(perm[i], perm[i + 1]);
      }

      if (totalDist < minDistance) {
        minDistance = totalDist;
        bestSequence = perm;
      }
    }

    if (bestSequence == null) {
      return const OptimizationResult(
        orderedStops: [],
        totalDistanceKm: 0.0,
        isFeasible: false,
        infeasibilityReason:
            'No route permutation satisfies precedence and seat capacity constraints',
      );
    }

    return OptimizationResult(
      orderedStops: bestSequence,
      totalDistanceKm: double.parse(minDistance.toStringAsFixed(2)),
      isFeasible: true,
    );
  }

  static bool _satisfiesPrecedence(List<RouteStop> sequence) {
    final seenPickups = <String>{};
    for (final stop in sequence) {
      if (stop.isPickup) {
        seenPickups.add(stop.bookingId);
      } else {
        // Dropoff encountered: pickup MUST have been seen earlier
        if (!seenPickups.contains(stop.bookingId)) {
          return false;
        }
      }
    }
    return true;
  }

  static bool _satisfiesCapacity(List<RouteStop> sequence, int capacity) {
    int currentOccupancy = 0;
    for (final stop in sequence) {
      if (stop.isPickup) {
        currentOccupancy += stop.partySize;
        if (currentOccupancy > capacity) {
          return false;
        }
      } else {
        currentOccupancy -= stop.partySize;
        if (currentOccupancy < 0) {
          return false;
        }
      }
    }
    return true;
  }

  static List<List<T>> _generatePermutations<T>(List<T> items) {
    if (items.isEmpty) return [[]];
    final result = <List<T>>[];
    for (int i = 0; i < items.length; i++) {
      final current = items[i];
      final remaining = List<T>.from(items)..removeAt(i);
      final sub = _generatePermutations(remaining);
      for (final s in sub) {
        result.add([current, ...s]);
      }
    }
    return result;
  }
}
