import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/cost_model.dart';
import 'package:ridepool_app/core/engine/detour_validator.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';
import 'package:ridepool_app/core/engine/route_optimizer.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

/// Request entering the rolling batch intake queue.
class BatchRideRequest extends Equatable {
  const BatchRideRequest({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    this.partySize = 1,
    required this.tier,
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? const _StaticEpoch();

  final String id;
  final String passengerName;
  final PuneLocation pickup;
  final PuneLocation dropoff;
  final int partySize;
  final VehicleTier tier;
  final DateTime requestedAt;

  @override
  List<Object?> get props => [
        id,
        passengerName,
        pickup,
        dropoff,
        partySize,
        tier,
      ];
}

class _StaticEpoch implements DateTime {
  const _StaticEpoch();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.fromMillisecondsSinceEpoch(0);
}

/// Represents an active fleet vehicle ready to take batch assignments.
class BatchVehicle extends Equatable {
  BatchVehicle({
    required this.id,
    required this.model,
    required this.licensePlate,
    required this.driverName,
    required this.driverRating,
    required this.tier,
    int? capacity,
    required this.currentLocation,
    int? availableSeats,
  })  : capacity = capacity ?? tier.capacity,
        availableSeats = availableSeats ?? (capacity ?? tier.capacity);

  final String id;
  final String model;
  final String licensePlate;
  final String driverName;
  final double driverRating;
  final VehicleTier tier;
  final int capacity;
  final PuneLocation currentLocation;
  final int availableSeats;

  @override
  List<Object?> get props => [
        id,
        model,
        licensePlate,
        driverName,
        driverRating,
        tier,
        capacity,
        currentLocation,
        availableSeats,
      ];
}

/// Reasons why a batch matching failed to form a feasible pool.
enum NoMatchReason {
  tierMismatch,
  capacityExceeded,
  detourExceeded,
  timeWindowExceeded,
}

/// Discrete outcome produced by the Combinatorial Batch Matcher.
sealed class BatchMatchingOutcome extends Equatable {
  const BatchMatchingOutcome();
}

/// Discrete State 1: Feasible pooled match found with guaranteed <=15% detour & Shapley savings.
class MatchFoundOutcome extends BatchMatchingOutcome {
  const MatchFoundOutcome({
    required this.vehicle,
    required this.matchedRequests,
    required this.totalSharedKm,
    required this.detourPercentage,
    required this.fareAllocation,
    required this.offer,
  });

  final BatchVehicle vehicle;
  final List<BatchRideRequest> matchedRequests;
  final double totalSharedKm;
  final double detourPercentage;
  final FareAllocationResult fareAllocation;
  final PooledRideOffer offer;

  @override
  List<Object?> get props => [
        vehicle,
        matchedRequests,
        totalSharedKm,
        detourPercentage,
        fareAllocation,
        offer,
      ];
}

/// Discrete State 2: No valid match with an explicit, truthful reason.
class NoValidMatchOutcome extends BatchMatchingOutcome {
  const NoValidMatchOutcome({
    required this.reason,
    required this.explanation,
    this.observedDetour,
  });

  final NoMatchReason reason;
  final String explanation;
  final double? observedDetour;

  @override
  List<Object?> get props => [reason, explanation, observedDetour];
}

/// Discrete State 3: Dispatched as a direct solo ride without detour.
class SoloDirectRideOutcome extends BatchMatchingOutcome {
  const SoloDirectRideOutcome({
    required this.vehicle,
    required this.request,
    required this.distanceKm,
    required this.soloFare,
    required this.explanation,
  });

  final BatchVehicle vehicle;
  final BatchRideRequest request;
  final double distanceKm;
  final double soloFare;
  final String explanation;

  @override
  List<Object?> get props => [
        vehicle,
        request,
        distanceKm,
        soloFare,
        explanation,
      ];
}

/// Combinatorial Batch Matching Engine.
///
/// Enforces:
/// 1. Strict vehicle tier boundaries: Auto with Auto, Car with Car, Car XL with Car XL.
/// 2. Vehicle seat capacity and individual party sizes.
/// 3. Precedence: Pickups before dropoffs.
/// 4. Strict detour guarantee: Detour <= 15.0% for all passengers in the coalition.
/// 5. Exact Shapley fair-fare calculations scaled by tier rate multiplier.
class CombinatorialBatchMatcher {
  CombinatorialBatchMatcher({
    this.estimator = const RouteEstimatorService(),
    this.detourValidator = const DetourValidator(maxDetourRatio: 0.15),
    this.costModel = const CostModel(),
  });

  final RouteEstimatorService estimator;
  final DetourValidator detourValidator;
  final CostModel costModel;

  BatchMatchingOutcome match({
    required BatchRideRequest targetRequest,
    required List<BatchRideRequest> queuedRequests,
    required List<BatchVehicle> availableVehicles,
    bool allowSoloFallback = true,
  }) {
    // 1. Strict Tier Vehicle Matching
    final matchingVehicles = availableVehicles
        .where((v) => v.tier == targetRequest.tier)
        .toList();

    if (matchingVehicles.isEmpty) {
      return NoValidMatchOutcome(
        reason: NoMatchReason.tierMismatch,
        explanation:
            'No active vehicle found matching ${targetRequest.tier.displayName} tier.',
      );
    }

    final vehicle = matchingVehicles.first;

    // 2. Capacity Check for Target Request
    if (!targetRequest.tier.canAccommodatePartySize(targetRequest.partySize) ||
        targetRequest.partySize > vehicle.availableSeats) {
      return NoValidMatchOutcome(
        reason: NoMatchReason.capacityExceeded,
        explanation:
            'Party size of ${targetRequest.partySize} exceeds ${targetRequest.tier.displayName} available capacity (${vehicle.availableSeats} seats).',
      );
    }

    // 3. Filter queued co-passenger requests by the exact same tier
    final compatibleQueue = queuedRequests
        .where((r) => r.tier == targetRequest.tier && r.id != targetRequest.id)
        .toList();

    // Direct distance of target user
    final targetSoloDistance = estimator.calculateDistanceKm(
      targetRequest.pickup,
      targetRequest.dropoff,
    );

    // If no co-passengers in queue, consider solo fallback or no-match
    if (compatibleQueue.isEmpty) {
      if (allowSoloFallback) {
        final soloFare = targetRequest.tier.calculateEstimatedFare(
          targetSoloDistance,
          costModel: costModel,
        );
        return SoloDirectRideOutcome(
          vehicle: vehicle,
          request: targetRequest,
          distanceKm: targetSoloDistance,
          soloFare: soloFare,
          explanation:
              'Direct solo ride in ${targetRequest.tier.displayName} with zero detour.',
        );
      }
      return const NoValidMatchOutcome(
        reason: NoMatchReason.timeWindowExceeded,
        explanation: 'No compatible co-passengers found in batch intake window.',
      );
    }

    // 4. Combinatorial Evaluation across subsets of compatible requests
    final subsets = _generateCoalitionSubsets(
      target: targetRequest,
      pool: compatibleQueue,
      maxCapacity: vehicle.capacity,
    );

    double? highestObservedDetour;
    bool capacityLimitEncountered = false;

    for (final coalition in subsets) {
      // Check total party size
      final totalPartySize = coalition.fold(0, (sum, r) => sum + r.partySize);
      if (totalPartySize > vehicle.capacity) {
        capacityLimitEncountered = true;
        continue;
      }

      // Convert coalition requests to RouteStops
      final stops = <RouteStop>[];
      for (final req in coalition) {
        stops.add(RouteStop(
          id: 'p_${req.id}',
          bookingId: req.id,
          isPickup: true,
          lat: req.pickup.latitude,
          lng: req.pickup.longitude,
          partySize: req.partySize,
        ));
        stops.add(RouteStop(
          id: 'd_${req.id}',
          bookingId: req.id,
          isPickup: false,
          lat: req.dropoff.latitude,
          lng: req.dropoff.longitude,
          partySize: req.partySize,
        ));
      }

      // Optimize stops with precedence & seat capacity
      final optResult = RouteOptimizer.optimize(
        stops: stops,
        vehicleCapacity: vehicle.capacity,
        distanceFn: (from, to) {
          final p1 = PuneLocation(name: from.id, latitude: from.lat, longitude: from.lng);
          final p2 = PuneLocation(name: to.id, latitude: to.lat, longitude: to.lng);
          return estimator.calculateDistanceKm(p1, p2);
        },
      );

      if (!optResult.isFeasible) {
        continue;
      }

      // A pooled trip requires concurrent overlap (at least 2 riders onboard together)
      if (coalition.length > 1 && _maxConcurrentOccupancy(optResult.orderedStops) < 2) {
        continue;
      }

      // Calculate in-vehicle route distance for each rider along the ordered sequence
      bool allDetoursValid = true;
      final bookingCandidates = <BookingCandidate>[];
      final detourMap = <String, double>{};

      for (final req in coalition) {
        final soloDist = estimator.calculateDistanceKm(req.pickup, req.dropoff);
        final sharedDist = _calculateInVehicleDistance(
          req.id,
          optResult.orderedStops,
        );

        final detourPct = detourValidator.calculateDetourPercent(soloDist, sharedDist);
        detourMap[req.id] = detourPct;

        if (highestObservedDetour == null || detourPct > highestObservedDetour) {
          highestObservedDetour = detourPct;
        }

        if (!detourValidator.isDetourValid(soloDist, sharedDist)) {
          allDetoursValid = false;
          break;
        }

        bookingCandidates.add(BookingCandidate(
          id: req.id,
          partySize: req.partySize,
          soloKm: soloDist,
          sharedKm: sharedDist,
        ));
      }

      if (!allDetoursValid) {
        continue;
      }

      // Detour guarantee is verified for all riders! Compute Shapley fares
      final fareAllocator = FareAllocator(
        costModel: costModel,
        detourValidator: detourValidator,
      );

      // Coalition sub-distances map
      final coalitionDistances = <String, double>{};
      for (final req in coalition) {
        coalitionDistances[req.id] = estimator.calculateDistanceKm(req.pickup, req.dropoff);
      }
      final allSortedKey = (coalition.map((r) => r.id).toList()..sort()).join(',');
      coalitionDistances[allSortedKey] = optResult.totalDistanceKm;

      final fareResult = fareAllocator.allocate(
        candidates: bookingCandidates,
        totalSharedKm: optResult.totalDistanceKm,
        coalitionDistancesKm: coalitionDistances,
        rateMultiplier: vehicle.tier.rateMultiplier,
      );

      if (!fareResult.isFeasible) {
        continue;
      }

      // Formulate PooledRideOffer for target user
      final userSoloFare = fareResult.soloFares[targetRequest.id] ??
          targetRequest.tier.calculateEstimatedFare(targetSoloDistance, costModel: costModel);
      final rawShared = fareResult.allocatedFares[targetRequest.id] ?? userSoloFare;
      final userSharedFare = rawShared > userSoloFare ? userSoloFare : rawShared;
      final userDetour = detourMap[targetRequest.id] ?? 0.0;

      final coRiders = coalition.where((r) => r.id != targetRequest.id).toList();

      final offer = PooledRideOffer(
        offerId: 'offer-batch-${DateTime.now().millisecondsSinceEpoch}',
        vehicleModel: vehicle.model,
        licensePlate: vehicle.licensePlate,
        driverName: vehicle.driverName,
        driverRating: vehicle.driverRating,
        pickup: targetRequest.pickup,
        dropoff: targetRequest.dropoff,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes:
            (estimator.calculateDurationMinutes(targetSoloDistance) * (1 + (userDetour / 100)))
                .round(),
        coPassengersCount: coRiders.fold(0, (sum, r) => sum + r.partySize),
        coPassengerLabels: coRiders
            .map((r) => '${r.passengerName} (${r.pickup.name.split(" ").first})')
            .toList(),
        detourPercentage: userDetour,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: userSoloFare,
          sharedFare: userSharedFare,
          coalitionSize: coalition.length,
          explanation:
              'Exact Shapley allocation for ${vehicle.tier.displayName} group. Guaranteed ≤15% detour.',
        ),
      );

      return MatchFoundOutcome(
        vehicle: vehicle,
        matchedRequests: coalition,
        totalSharedKm: optResult.totalDistanceKm,
        detourPercentage: userDetour,
        fareAllocation: fareResult,
        offer: offer,
      );
    }

    // If loop finishes without returning a match:
    if (highestObservedDetour != null && highestObservedDetour > 15.0) {
      if (allowSoloFallback) {
        final soloFare = targetRequest.tier.calculateEstimatedFare(
          targetSoloDistance,
          costModel: costModel,
        );
        return SoloDirectRideOutcome(
          vehicle: vehicle,
          request: targetRequest,
          distanceKm: targetSoloDistance,
          soloFare: soloFare,
          explanation:
              'Direct solo ride offered because available pooled options exceed the 15% detour guarantee (${highestObservedDetour.toStringAsFixed(1)}%).',
        );
      }
      return NoValidMatchOutcome(
        reason: NoMatchReason.detourExceeded,
        explanation:
            'All pooled coalitions exceeded the 15% detour guarantee (observed: ${highestObservedDetour.toStringAsFixed(1)}%).',
        observedDetour: highestObservedDetour,
      );
    }

    if (capacityLimitEncountered) {
      return const NoValidMatchOutcome(
        reason: NoMatchReason.capacityExceeded,
        explanation:
            'Combined requests exceed maximum available seat capacity.',
      );
    }

    if (allowSoloFallback) {
      final soloFare = targetRequest.tier.calculateEstimatedFare(
        targetSoloDistance,
        costModel: costModel,
      );
      return SoloDirectRideOutcome(
        vehicle: vehicle,
        request: targetRequest,
        distanceKm: targetSoloDistance,
        soloFare: soloFare,
        explanation: 'Direct solo ride dispatched with no pooling detour.',
      );
    }

    return const NoValidMatchOutcome(
      reason: NoMatchReason.timeWindowExceeded,
      explanation: 'No valid match found within batch processing window.',
    );
  }

  int _maxConcurrentOccupancy(List<RouteStop> sequence) {
    int current = 0;
    int maxOcc = 0;
    for (final stop in sequence) {
      if (stop.isPickup) {
        current += stop.partySize;
        if (current > maxOcc) maxOcc = current;
      } else {
        current -= stop.partySize;
      }
    }
    return maxOcc;
  }

  double _calculateInVehicleDistance(
    String bookingId,
    List<RouteStop> orderedStops,
  ) {
    int pickupIdx = -1;
    int dropoffIdx = -1;

    for (int i = 0; i < orderedStops.length; i++) {
      if (orderedStops[i].bookingId == bookingId) {
        if (orderedStops[i].isPickup) {
          pickupIdx = i;
        } else {
          dropoffIdx = i;
        }
      }
    }

    if (pickupIdx == -1 || dropoffIdx == -1 || pickupIdx >= dropoffIdx) {
      return 0.0;
    }

    double distance = 0.0;
    for (int i = pickupIdx; i < dropoffIdx; i++) {
      final from = orderedStops[i];
      final to = orderedStops[i + 1];
      final p1 = PuneLocation(name: from.id, latitude: from.lat, longitude: from.lng);
      final p2 = PuneLocation(name: to.id, latitude: to.lat, longitude: to.lng);
      distance += estimator.calculateDistanceKm(p1, p2);
    }

    return double.parse(distance.toStringAsFixed(2));
  }

  List<List<BatchRideRequest>> _generateCoalitionSubsets({
    required BatchRideRequest target,
    required List<BatchRideRequest> pool,
    required int maxCapacity,
  }) {
    final results = <List<BatchRideRequest>>[];

    // Order permutations by coalition size: largest feasible first
    for (int size = pool.length; size >= 1; size--) {
      _combinations(pool, size, (combo) {
        results.add([target, ...combo]);
      });
    }

    return results;
  }

  void _combinations(
    List<BatchRideRequest> list,
    int length,
    void Function(List<BatchRideRequest>) onCombination, [
    int startIndex = 0,
    List<BatchRideRequest>? current,
  ]) {
    final curr = current ?? [];
    if (curr.length == length) {
      onCombination(List<BatchRideRequest>.from(curr));
      return;
    }

    for (int i = startIndex; i < list.length; i++) {
      curr.add(list[i]);
      _combinations(list, length, onCombination, i + 1, curr);
      curr.removeLast();
    }
  }
}

/// Rolling batch intake queue holding incoming requests for a configurable window.
class RollingBatchIntakeQueue {
  RollingBatchIntakeQueue({
    this.windowSeconds = 15,
  }) {
    if (windowSeconds < 15 || windowSeconds > 90) {
      throw ArgumentError.value(
        windowSeconds,
        'windowSeconds',
        'Batch intake window must be configured between 15 and 90 seconds.',
      );
    }
  }

  final int windowSeconds;
  final List<BatchRideRequest> _queue = [];

  int get queuedCount => _queue.length;

  List<BatchRideRequest> get pendingRequests => List.unmodifiable(_queue);

  void enqueue(BatchRideRequest request) {
    _queue.add(request);
  }

  List<BatchRideRequest> drainBatch() {
    final batch = List<BatchRideRequest>.from(_queue);
    _queue.clear();
    return batch;
  }
}
