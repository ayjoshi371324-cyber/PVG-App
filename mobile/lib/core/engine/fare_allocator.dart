import 'package:ridepool_app/core/engine/cost_model.dart';
import 'package:ridepool_app/core/engine/detour_validator.dart';
import 'package:ridepool_app/core/engine/shapley_calculator.dart';

/// Represents an incoming passenger booking request for fare allocation.
class BookingCandidate {
  final String id;
  final int partySize;
  final double soloKm;
  final double sharedKm;

  const BookingCandidate({
    required this.id,
    required this.partySize,
    required this.soloKm,
    required this.sharedKm,
  });
}

/// Comprehensive outcome of the Fair-Fare Allocation engine.
class FareAllocationResult {
  final bool isFeasible;
  final String? rejectionReason;
  final double totalTripCost;
  final Map<String, double> soloFares;
  final Map<String, double> allocatedFares;
  final Map<String, double> rawShares;
  final Map<String, double> perPersonFares;
  final Map<String, double> savings;
  final Map<String, double> detourPercentages;
  final Map<String, double> coalitionTable;

  const FareAllocationResult({
    required this.isFeasible,
    this.rejectionReason,
    required this.totalTripCost,
    required this.soloFares,
    required this.allocatedFares,
    required this.rawShares,
    required this.perPersonFares,
    required this.savings,
    required this.detourPercentages,
    required this.coalitionTable,
  });
}

/// High-level Fair-Fare Allocation Engine.
class FareAllocator {
  final CostModel costModel;
  final DetourValidator detourValidator;

  const FareAllocator({
    this.costModel = const CostModel(),
    this.detourValidator = const DetourValidator(maxDetourRatio: 0.15),
  });

  /// Evaluates pooling feasibility and computes exact Shapley fare allocation.
  FareAllocationResult allocate({
    required List<BookingCandidate> candidates,
    required double totalSharedKm,
    required Map<String, double> coalitionDistancesKm,
    double rateMultiplier = 1.0,
  }) {
    if (candidates.isEmpty) {
      return const FareAllocationResult(
        isFeasible: false,
        rejectionReason: 'No candidates provided',
        totalTripCost: 0.0,
        soloFares: {},
        allocatedFares: {},
        rawShares: {},
        perPersonFares: {},
        savings: {},
        detourPercentages: {},
        coalitionTable: {},
      );
    }

    final soloFares = <String, double>{};
    final detourPercentages = <String, double>{};
    final partySizes = <String, int>{};
    final playerIds = <String>[];

    // 1. Verify detour constraints for each candidate
    for (final candidate in candidates) {
      playerIds.add(candidate.id);
      partySizes[candidate.id] = candidate.partySize;

      final soloFare = costModel.tripCost(candidate.soloKm, multiplier: rateMultiplier);
      soloFares[candidate.id] = soloFare;

      final detourPct = detourValidator.calculateDetourPercent(
        candidate.soloKm,
        candidate.sharedKm,
      );
      detourPercentages[candidate.id] = detourPct;

      if (!detourValidator.isDetourValid(candidate.soloKm, candidate.sharedKm)) {
        return FareAllocationResult(
          isFeasible: false,
          rejectionReason:
              'Detour for rider ${candidate.id} (${detourPct.toStringAsFixed(1)}%) exceeds the 15% maximum guarantee',
          totalTripCost: 0.0,
          soloFares: soloFares,
          allocatedFares: {},
          rawShares: {},
          perPersonFares: {},
          savings: {},
          detourPercentages: detourPercentages,
          coalitionTable: {},
        );
      }
    }

    // 2. Build the coalition cost table v(S)
    final totalTripCost = costModel.tripCost(totalSharedKm, multiplier: rateMultiplier);
    final coalitionTable = <String, double>{};

    double coalitionCostFn(Set<String> subset) {
      if (subset.isEmpty) return 0.0;
      final sortedKey = (subset.toList()..sort()).join(',');
      if (coalitionTable.containsKey(sortedKey)) {
        return coalitionTable[sortedKey]!;
      }

      // Look up distance for coalition subset
      double distKm = totalSharedKm;
      if (coalitionDistancesKm.containsKey(sortedKey)) {
        distKm = coalitionDistancesKm[sortedKey]!;
      } else if (subset.length == 1) {
        final single = candidates.firstWhere((c) => c.id == subset.first);
        distKm = single.soloKm;
      }

      final cost = costModel.tripCost(distKm, multiplier: rateMultiplier);
      coalitionTable[sortedKey] = cost;
      return cost;
    }

    // Populate coalition table for all combinations
    final shapleyResult = ShapleyCalculator.calculate(
      players: playerIds,
      coalitionCost: coalitionCostFn,
      totalCost: totalTripCost,
      soloFares: soloFares,
      partySizes: partySizes,
    );

    return FareAllocationResult(
      isFeasible: true,
      totalTripCost: totalTripCost,
      soloFares: soloFares,
      allocatedFares: shapleyResult.roundedShares,
      rawShares: shapleyResult.rawShares,
      perPersonFares: shapleyResult.perPersonShares,
      savings: shapleyResult.savings,
      detourPercentages: detourPercentages,
      coalitionTable: coalitionTable,
    );
  }
}
