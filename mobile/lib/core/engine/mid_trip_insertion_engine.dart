import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/cost_model.dart';
import 'package:ridepool_app/core/engine/detour_validator.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';
import 'package:ridepool_app/core/engine/route_optimizer.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

/// Active passenger already onboard the in-flight vehicle.
class InFlightPassenger extends Equatable {
  const InFlightPassenger({
    required this.bookingId,
    required this.passengerName,
    required this.soloDistanceKm,
    required this.currentFare,
    required this.partySize,
    required this.dropoff,
    required this.estimatedEtaMinutes,
    this.distanceTraveledKm = 0.0,
    this.currentDetourPercentage = 0.0,
  });

  final String bookingId;
  final String passengerName;
  final double soloDistanceKm;
  final double currentFare;
  final int partySize;
  final PuneLocation dropoff;
  final int estimatedEtaMinutes;
  final double distanceTraveledKm;
  final double currentDetourPercentage;

  @override
  List<Object?> get props => [
        bookingId,
        passengerName,
        soloDistanceKm,
        currentFare,
        partySize,
        dropoff,
        estimatedEtaMinutes,
        distanceTraveledKm,
        currentDetourPercentage,
      ];
}

/// Incoming candidate requesting to join an in-flight vehicle mid-trip.
class CandidateJoinRequest extends Equatable {
  const CandidateJoinRequest({
    required this.bookingId,
    required this.passengerName,
    required this.pickup,
    required this.dropoff,
    required this.partySize,
  });

  final String bookingId;
  final String passengerName;
  final PuneLocation pickup;
  final PuneLocation dropoff;
  final int partySize;

  @override
  List<Object?> get props => [
        bookingId,
        passengerName,
        pickup,
        dropoff,
        partySize,
      ];
}

/// Explicit route, ETA, and fare delta computed for an existing passenger.
class ExistingRiderDelta extends Equatable {
  const ExistingRiderDelta({
    required this.bookingId,
    required this.passengerName,
    required this.previousFare,
    required this.updatedFare,
    required this.fareSavingsDelta,
    required this.previousEtaMinutes,
    required this.updatedEtaMinutes,
    required this.etaDeltaMinutes,
    required this.previousDetourPercentage,
    required this.updatedDetourPercentage,
    required this.detourDeltaPercentage,
  });

  final String bookingId;
  final String passengerName;
  final double previousFare;
  final double updatedFare;
  final double fareSavingsDelta;
  final int previousEtaMinutes;
  final int updatedEtaMinutes;
  final int etaDeltaMinutes;
  final double previousDetourPercentage;
  final double updatedDetourPercentage;
  final double detourDeltaPercentage;

  @override
  List<Object?> get props => [
        bookingId,
        passengerName,
        previousFare,
        updatedFare,
        fareSavingsDelta,
        previousEtaMinutes,
        updatedEtaMinutes,
        etaDeltaMinutes,
        previousDetourPercentage,
        updatedDetourPercentage,
        detourDeltaPercentage,
      ];
}

/// Complete proposal generated when mid-trip insertion is feasible.
class MidTripJoinProposal extends Equatable {
  const MidTripJoinProposal({
    required this.proposalId,
    required this.candidateId,
    required this.candidateName,
    required this.candidatePickup,
    required this.candidateDropoff,
    required this.candidatePartySize,
    required this.candidateFare,
    required this.candidateSoloFare,
    required this.newDetourPercentage,
    required this.previousDetourPercentage,
    required this.additionalSavings,
    required this.newTotalDistanceKm,
    required this.orderedStops,
    required this.existingRiderDeltas,
  });

  final String proposalId;
  final String candidateId;
  final String candidateName;
  final PuneLocation candidatePickup;
  final PuneLocation candidateDropoff;
  final int candidatePartySize;
  final double candidateFare;
  final double candidateSoloFare;
  final double newDetourPercentage;
  final double previousDetourPercentage;
  final double additionalSavings;
  final double newTotalDistanceKm;
  final List<RouteStop> orderedStops;
  final Map<String, ExistingRiderDelta> existingRiderDeltas;

  /// Helper to convert to MidTripJoinRequest used by ActiveTrip & UI sheets
  MidTripJoinRequest toJoinRequest() {
    final firstRider = existingRiderDeltas.values.isNotEmpty
        ? existingRiderDeltas.values.first
        : null;

    return MidTripJoinRequest(
      requestId: proposalId,
      passengerName: candidateName,
      pickupLocation: candidatePickup,
      dropoffLocation: candidateDropoff,
      previousDetourPercentage: firstRider?.previousDetourPercentage ?? previousDetourPercentage,
      newDetourPercentage: newDetourPercentage,
      additionalSavings: firstRider?.fareSavingsDelta ?? additionalSavings,
      newSharedFare: firstRider?.updatedFare ?? candidateFare,
    );
  }

  @override
  List<Object?> get props => [
        proposalId,
        candidateId,
        candidateName,
        candidatePickup,
        candidateDropoff,
        candidatePartySize,
        candidateFare,
        candidateSoloFare,
        newDetourPercentage,
        previousDetourPercentage,
        additionalSavings,
        newTotalDistanceKm,
        orderedStops,
        existingRiderDeltas,
      ];
}

/// Result of evaluating a candidate mid-trip insertion.
class MidTripInsertionResult extends Equatable {
  const MidTripInsertionResult({
    required this.isFeasible,
    this.rejectionReason,
    this.proposal,
  });

  final bool isFeasible;
  final String? rejectionReason;
  final MidTripJoinProposal? proposal;

  @override
  List<Object?> get props => [isFeasible, rejectionReason, proposal];
}

/// Deterministic Mid-Trip Insertion Engine.
///
/// Evaluates candidate pickup and dropoff insertions along the in-flight
/// vehicle's remaining route, strictly rejecting requests exceeding 15% detour
/// or cabin seat capacity at any segment.
class MidTripInsertionEngine {
  const MidTripInsertionEngine({
    this.estimator = const RouteEstimatorService(),
    this.costModel = const CostModel(),
    this.detourValidator = const DetourValidator(maxDetourRatio: 0.15),
  });

  final RouteEstimatorService estimator;
  final CostModel costModel;
  final DetourValidator detourValidator;

  MidTripInsertionResult evaluate({
    required PuneLocation currentLocation,
    required int vehicleCapacity,
    required List<InFlightPassenger> currentOnboardPassengers,
    required CandidateJoinRequest candidate,
    double rateMultiplier = 1.0,
  }) {
    // 1. Initial quick capacity check: can the vehicle hold onboard + candidate at all?
    final totalOnboardSeats = currentOnboardPassengers.fold<int>(
      0,
      (sum, p) => sum + p.partySize,
    );

    if (totalOnboardSeats + candidate.partySize > vehicleCapacity) {
      return MidTripInsertionResult(
        isFeasible: false,
        rejectionReason:
            'Capacity exceeded: Vehicle capacity ($vehicleCapacity) cannot accommodate candidate (${candidate.partySize} seats) with $totalOnboardSeats onboard seats.',
      );
    }

    // 2. Candidate direct route
    final candidateSoloEstimate = estimator.estimateRoute(
      pickup: candidate.pickup,
      dropoff: candidate.dropoff,
      rateMultiplier: rateMultiplier,
    );
    final candidateSoloKm = candidateSoloEstimate.distanceKm;

    // 3. Define the stops to visit from currentLocation
    // Stops include: candidate pickup, candidate dropoff, and each onboard passenger's dropoff.
    final candidatePickupStop = RouteStop(
      id: 'stop-pickup-${candidate.bookingId}',
      bookingId: candidate.bookingId,
      isPickup: true,
      lat: candidate.pickup.latitude,
      lng: candidate.pickup.longitude,
      partySize: candidate.partySize,
    );

    final candidateDropoffStop = RouteStop(
      id: 'stop-dropoff-${candidate.bookingId}',
      bookingId: candidate.bookingId,
      isPickup: false,
      lat: candidate.dropoff.latitude,
      lng: candidate.dropoff.longitude,
      partySize: candidate.partySize,
    );

    final passengerDropoffStops = currentOnboardPassengers.map((p) {
      return RouteStop(
        id: 'stop-dropoff-${p.bookingId}',
        bookingId: p.bookingId,
        isPickup: false,
        lat: p.dropoff.latitude,
        lng: p.dropoff.longitude,
        partySize: p.partySize,
      );
    }).toList();

    final allPendingStops = [
      candidatePickupStop,
      candidateDropoffStop,
      ...passengerDropoffStops,
    ];

    // Distance helper between RouteStops
    double stopDistance(RouteStop a, RouteStop b) {
      final locA = PuneLocation(name: a.id, latitude: a.lat, longitude: a.lng);
      final locB = PuneLocation(name: b.id, latitude: b.lat, longitude: b.lng);
      return estimator.estimateRoute(pickup: locA, dropoff: locB).distanceKm;
    }

    // Distance from current vehicle location to a RouteStop
    double fromCurrentDistance(RouteStop s) {
      final locS = PuneLocation(name: s.id, latitude: s.lat, longitude: s.lng);
      return estimator.estimateRoute(pickup: currentLocation, dropoff: locS).distanceKm;
    }

    // 4. Find all feasible permutations of allPendingStops
    // Must satisfy:
    // a) Candidate pickup before candidate dropoff
    // b) Segment-by-segment cabin capacity:
    //    Starting occupancy = totalOnboardSeats
    //    Along sequence:
    //      if stop.isPickup: occupancy += stop.partySize
    //      if !stop.isPickup: occupancy -= stop.partySize
    //      occupancy must stay <= vehicleCapacity at all points!
    // c) For candidate & each existing passenger: Detour <= 15.0%
    final permutations = _generatePermutations(allPendingStops);

    List<RouteStop>? bestSequence;
    double minTotalDistance = double.infinity;
    Map<String, double>? bestPassengerSharedKm;
    double? bestCandidateSharedKm;

    for (final perm in permutations) {
      // Check precedence: candidate pickup must come before candidate dropoff
      final pickupIdx = perm.indexOf(candidatePickupStop);
      final dropoffIdx = perm.indexOf(candidateDropoffStop);
      if (pickupIdx == -1 || dropoffIdx == -1 || pickupIdx > dropoffIdx) {
        continue;
      }

      // Candidate must join while an existing passenger is onboard (pickup before dropoff)
      final hasOverlap = currentOnboardPassengers.isEmpty ||
          currentOnboardPassengers.any((p) {
            final dIdx = perm.indexWhere(
              (s) => s.bookingId == p.bookingId && !s.isPickup,
            );
            return dIdx != -1 && pickupIdx < dIdx;
          });
      if (!hasOverlap) {
        continue;
      }

      // Check segment-by-segment cabin capacity
      int occupancy = totalOnboardSeats;
      bool capacityFeasible = true;
      for (final stop in perm) {
        if (stop.isPickup) {
          occupancy += stop.partySize;
          if (occupancy > vehicleCapacity) {
            capacityFeasible = false;
            break;
          }
        } else {
          occupancy -= stop.partySize;
          if (occupancy < 0) {
            capacityFeasible = false;
            break;
          }
        }
      }
      if (!capacityFeasible) {
        continue;
      }

      // Calculate path segments and cumulative distances
      // Leg 0: currentLocation -> perm[0]
      final legDistances = <double>[];
      legDistances.add(fromCurrentDistance(perm[0]));
      for (int i = 0; i < perm.length - 1; i++) {
        legDistances.add(stopDistance(perm[i], perm[i + 1]));
      }

      final totalRouteDist = legDistances.fold(0.0, (s, d) => s + d);

      // Measure travel distance for candidate: from perm[pickupIdx] to perm[dropoffIdx]
      double candidateTravelKm = 0.0;
      for (int i = pickupIdx; i < dropoffIdx; i++) {
        candidateTravelKm += legDistances[i + 1];
      }

      // Measure travel distance for each onboard passenger:
      // from currentLocation to perm[theirDropoffIdx]
      final passengerSharedKm = <String, double>{};
      bool allDetoursValid = true;
      double maxDetourObserved = 0.0;

      // Candidate detour check
      final candidateDetourPct = detourValidator.calculateDetourPercent(
        candidateSoloKm,
        candidateTravelKm,
      );
      if (candidateDetourPct > maxDetourObserved) {
        maxDetourObserved = candidateDetourPct;
      }
      if (!detourValidator.isDetourValid(candidateSoloKm, candidateTravelKm)) {
        allDetoursValid = false;
      }

      // Onboard passengers detour check
      for (final p in currentOnboardPassengers) {
        final dIdx = perm.indexWhere(
          (s) => s.bookingId == p.bookingId && !s.isPickup,
        );
        if (dIdx == -1) {
          allDetoursValid = false;
          break;
        }

        // Distance from currentLocation to dropoff along this sequence
        double distFromCurrentToDropoff = legDistances[0];
        for (int i = 0; i < dIdx; i++) {
          distFromCurrentToDropoff += legDistances[i + 1];
        }

        final totalPaxKm = p.distanceTraveledKm + distFromCurrentToDropoff;
        passengerSharedKm[p.bookingId] = totalPaxKm;

        final paxDetourPct = detourValidator.calculateDetourPercent(
          p.soloDistanceKm,
          totalPaxKm,
        );
        if (paxDetourPct > maxDetourObserved) {
          maxDetourObserved = paxDetourPct;
        }

        if (!detourValidator.isDetourValid(p.soloDistanceKm, totalPaxKm)) {
          allDetoursValid = false;
          break;
        }
      }

      if (allDetoursValid && totalRouteDist < minTotalDistance) {
        minTotalDistance = totalRouteDist;
        bestSequence = perm;
        bestPassengerSharedKm = passengerSharedKm;
        bestCandidateSharedKm = candidateTravelKm;
      }
    }

    if (bestSequence == null) {
      return MidTripInsertionResult(
        isFeasible: false,
        rejectionReason:
            'Detour guarantee violation: Insertion exceeds the 15% maximum detour limit for one or more riders.',
      );
    }

    // 5. Compute fair-fares using exact Shapley allocation across the coalition
    final candidateCandidates = [
      ...currentOnboardPassengers.map((p) => BookingCandidate(
            id: p.bookingId,
            partySize: p.partySize,
            soloKm: p.soloDistanceKm,
            sharedKm: bestPassengerSharedKm![p.bookingId]!,
          )),
      BookingCandidate(
        id: candidate.bookingId,
        partySize: candidate.partySize,
        soloKm: candidateSoloKm,
        sharedKm: bestCandidateSharedKm!,
      ),
    ];

    final allocator = FareAllocator(
      costModel: costModel,
      detourValidator: detourValidator,
    );

    final allocationResult = allocator.allocate(
      candidates: candidateCandidates,
      totalSharedKm: minTotalDistance,
      coalitionDistancesKm: {},
      rateMultiplier: rateMultiplier,
    );

    if (!allocationResult.isFeasible) {
      return MidTripInsertionResult(
        isFeasible: false,
        rejectionReason: allocationResult.rejectionReason,
      );
    }

    // 6. Assemble deltas for all existing riders
    final existingRiderDeltas = <String, ExistingRiderDelta>{};

    for (final p in currentOnboardPassengers) {
      final newFare = allocationResult.allocatedFares[p.bookingId] ?? p.currentFare;
      final savingsDelta = (p.currentFare - newFare).clamp(0.0, p.currentFare);
      final newDetour = allocationResult.detourPercentages[p.bookingId] ?? 0.0;
      final detourDelta = newDetour - p.currentDetourPercentage;

      // Calculate updated ETA for this passenger
      final dIdx = bestSequence.indexWhere(
        (s) => s.bookingId == p.bookingId && !s.isPickup,
      );
      double distToDropoff = fromCurrentDistance(bestSequence[0]);
      for (int i = 0; i < dIdx; i++) {
        distToDropoff += stopDistance(bestSequence[i], bestSequence[i + 1]);
      }
      final updatedEta = estimator.calculateDurationMinutes(distToDropoff);
      final etaDelta = updatedEta - p.estimatedEtaMinutes;

      existingRiderDeltas[p.bookingId] = ExistingRiderDelta(
        bookingId: p.bookingId,
        passengerName: p.passengerName,
        previousFare: p.currentFare,
        updatedFare: newFare,
        fareSavingsDelta: savingsDelta,
        previousEtaMinutes: p.estimatedEtaMinutes,
        updatedEtaMinutes: updatedEta,
        etaDeltaMinutes: etaDelta,
        previousDetourPercentage: p.currentDetourPercentage,
        updatedDetourPercentage: newDetour,
        detourDeltaPercentage: detourDelta,
      );
    }

    final candidateFare = allocationResult.allocatedFares[candidate.bookingId] ??
        candidateSoloEstimate.referenceFare;
    final candidateDetour = allocationResult.detourPercentages[candidate.bookingId] ?? 0.0;

    final proposal = MidTripJoinProposal(
      proposalId: 'prop-${DateTime.now().millisecondsSinceEpoch}',
      candidateId: candidate.bookingId,
      candidateName: candidate.passengerName,
      candidatePickup: candidate.pickup,
      candidateDropoff: candidate.dropoff,
      candidatePartySize: candidate.partySize,
      candidateFare: candidateFare,
      candidateSoloFare: candidateSoloEstimate.referenceFare,
      newDetourPercentage: candidateDetour,
      previousDetourPercentage: currentOnboardPassengers.isNotEmpty
          ? currentOnboardPassengers.first.currentDetourPercentage
          : 0.0,
      additionalSavings: existingRiderDeltas.values.isNotEmpty
          ? existingRiderDeltas.values.first.fareSavingsDelta
          : 0.0,
      newTotalDistanceKm: minTotalDistance,
      orderedStops: bestSequence,
      existingRiderDeltas: existingRiderDeltas,
    );

    return MidTripInsertionResult(
      isFeasible: true,
      proposal: proposal,
    );
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
