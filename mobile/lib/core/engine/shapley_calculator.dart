/// Result of a Shapley Value Cost Allocation calculation.
class ShapleyResult {
  final Map<String, double> rawShares;
  final Map<String, double> roundedShares;
  final Map<String, double> perPersonShares;
  final Map<String, double> roundingAdjustments;
  final Map<String, double> savings;
  final Map<String, bool> capTriggered;
  final double totalCost;

  const ShapleyResult({
    required this.rawShares,
    required this.roundedShares,
    required this.perPersonShares,
    required this.roundingAdjustments,
    required this.savings,
    required this.capTriggered,
    required this.totalCost,
  });
}

/// Exact Shapley Value Calculator for Cooperative Cost Games.
///
/// Implements:
/// 1. Exact enumeration of permutations: `Shapley_i = (1/n!) * \sum_{\pi} [v(S_i \cup {i}) - v(S_i)]`
/// 2. Solo-fare ceiling cap with proportional excess redistribution.
/// 3. Largest-remainder rounding ensuring `\sum shares == totalCost` to the exact paise.
/// 4. Per-booking party-size splitting.
class ShapleyCalculator {
  /// Calculates the Shapley cost allocation for a set of [players].
  ///
  /// - [players]: List of unique player identifiers (bookings).
  /// - [coalitionCost]: Characteristic function v(S) returning minimum cost for coalition S.
  /// - [totalCost]: Total pooled ride cost v(N).
  /// - [soloFares]: Map of player to their solo direct trip cost.
  /// - [partySizes]: Optional map of player to their party size (default 1).
  static ShapleyResult calculate({
    required List<String> players,
    required double Function(Set<String> subset) coalitionCost,
    required double totalCost,
    required Map<String, double> soloFares,
    Map<String, int>? partySizes,
  }) {
    if (players.isEmpty) {
      return ShapleyResult(
        rawShares: {},
        roundedShares: {},
        perPersonShares: {},
        roundingAdjustments: {},
        savings: {},
        capTriggered: {},
        totalCost: 0.0,
      );
    }

    final permutations = _generatePermutations(players);
    final numPermutations = permutations.length;

    // 1. Compute marginal contributions across all permutations
    final marginalSums = <String, double>{for (var p in players) p: 0.0};

    for (final perm in permutations) {
      final currentSubset = <String>{};
      double previousCost = 0.0;

      for (final player in perm) {
        currentSubset.add(player);
        final currentCost = coalitionCost(Set.unmodifiable(currentSubset));
        final marginalContribution = currentCost - previousCost;
        marginalSums[player] = (marginalSums[player] ?? 0.0) + marginalContribution;
        previousCost = currentCost;
      }
    }

    final rawShares = <String, double>{};
    for (final player in players) {
      rawShares[player] = (marginalSums[player] ?? 0.0) / numPermutations;
    }

    // 2. Solo-fare ceiling cap enforcement and redistribution
    final adjustedShares = Map<String, double>.from(rawShares);
    final capTriggered = <String, bool>{for (var p in players) p: false};

    bool rebalanced = true;
    int iteration = 0;
    while (rebalanced && iteration < 10) {
      rebalanced = false;
      iteration++;

      double excess = 0.0;
      final uncappedPlayers = <String>[];

      for (final player in players) {
        final soloFare = soloFares[player] ?? double.infinity;
        final currentShare = adjustedShares[player] ?? 0.0;

        if (currentShare > soloFare + 1e-6) {
          excess += (currentShare - soloFare);
          adjustedShares[player] = soloFare;
          capTriggered[player] = true;
          rebalanced = true;
        } else if (!capTriggered[player]!) {
          uncappedPlayers.add(player);
        }
      }

      if (rebalanced && excess > 0.0 && uncappedPlayers.isNotEmpty) {
        // Redistribute excess proportionally among uncapped players
        final uncappedSum = uncappedPlayers.fold(
          0.0,
          (sum, p) => sum + (adjustedShares[p] ?? 0.0),
        );
        if (uncappedSum > 0.0) {
          for (final p in uncappedPlayers) {
            final shareRatio = (adjustedShares[p] ?? 0.0) / uncappedSum;
            adjustedShares[p] = (adjustedShares[p] ?? 0.0) + (excess * shareRatio);
          }
        } else {
          final evenSplit = excess / uncappedPlayers.length;
          for (final p in uncappedPlayers) {
            adjustedShares[p] = (adjustedShares[p] ?? 0.0) + evenSplit;
          }
        }
      }
    }

    // 3. Largest-remainder rounding in integer paise (paise = 1/100 of rupee)
    final totalPaise = (totalCost * 100).round();
    final floorPaiseMap = <String, int>{};
    final remainderMap = <String, double>{};

    int sumFloorPaise = 0;
    for (final p in players) {
      final paiseVal = (adjustedShares[p] ?? 0.0) * 100;
      final floorVal = paiseVal.floor();
      floorPaiseMap[p] = floorVal;
      remainderMap[p] = paiseVal - floorVal;
      sumFloorPaise += floorVal;
    }

    int remainingPaise = totalPaise - sumFloorPaise;
    final sortedByRemainder = List<String>.from(players)
      ..sort((a, b) => remainderMap[b]!.compareTo(remainderMap[a]!));

    final roundedPaiseMap = Map<String, int>.from(floorPaiseMap);
    for (int i = 0; i < remainingPaise && i < sortedByRemainder.length; i++) {
      final p = sortedByRemainder[i];
      roundedPaiseMap[p] = (roundedPaiseMap[p] ?? 0) + 1;
    }

    final roundedShares = <String, double>{};
    final roundingAdjustments = <String, double>{};
    final perPersonShares = <String, double>{};
    final savings = <String, double>{};

    for (final p in players) {
      final share = (roundedPaiseMap[p] ?? 0) / 100.0;
      roundedShares[p] = share;
      roundingAdjustments[p] = double.parse(
        (share - (adjustedShares[p] ?? 0.0)).toStringAsFixed(4),
      );

      final pSize = partySizes?[p] ?? 1;
      perPersonShares[p] = double.parse(
        (share / (pSize > 0 ? pSize : 1)).toStringAsFixed(2),
      );

      final solo = soloFares[p] ?? share;
      savings[p] = double.parse(
        (solo - share < 0.0 ? 0.0 : solo - share).toStringAsFixed(2),
      );
    }

    return ShapleyResult(
      rawShares: rawShares,
      roundedShares: roundedShares,
      perPersonShares: perPersonShares,
      roundingAdjustments: roundingAdjustments,
      savings: savings,
      capTriggered: capTriggered,
      totalCost: totalCost,
    );
  }

  static List<List<T>> _generatePermutations<T>(List<T> items) {
    if (items.isEmpty) return [[]];
    final result = <List<T>>[];
    for (int i = 0; i < items.length; i++) {
      final current = items[i];
      final remaining = List<T>.from(items)..removeAt(i);
      final subPermutations = _generatePermutations(remaining);
      for (final sub in subPermutations) {
        result.add([current, ...sub]);
      }
    }
    return result;
  }
}
