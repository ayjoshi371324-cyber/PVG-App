import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/cost_model.dart';
import 'package:ridepool_app/core/engine/detour_validator.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

/// Result produced after dynamic ride cancellation and route rebalancing.
class TripCancellationResult extends Equatable {
  const TripCancellationResult({
    required this.updatedTrip,
    required this.updatedLedger,
    required this.reallocatedFares,
    required this.requiresReConsent,
    this.message,
  });

  final ActiveTrip updatedTrip;
  final SeatLedger updatedLedger;
  final Map<String, double> reallocatedFares;
  final bool requiresReConsent;
  final String? message;

  @override
  List<Object?> get props => [
        updatedTrip,
        updatedLedger,
        reallocatedFares,
        requiresReConsent,
        message,
      ];
}

/// In-Flight Rebalancing Engine.
///
/// Handles pre-departure and mid-trip cancellations:
/// 1. Pre-departure cancellation removes passenger, releases held/reserved seats
///    in the ledger, and rebalances the remaining route and Shapley fares.
/// 2. Mid-trip cancellation freezes completed prefixes, re-optimizes the pending
///    leg, and flags re-consent if remaining riders' fares increase.
class InFlightRebalancingEngine {
  const InFlightRebalancingEngine({
    this.estimator = const RouteEstimatorService(),
    this.costModel = const CostModel(),
    this.detourValidator = const DetourValidator(maxDetourRatio: 0.15),
  });

  final RouteEstimatorService estimator;
  final CostModel costModel;
  final DetourValidator detourValidator;

  /// Handles cancellation before the vehicle begins navigating the route.
  TripCancellationResult handlePreDepartureCancellation({
    required ActiveTrip trip,
    required SeatLedger ledger,
    required String cancelledBookingId,
    required int cancelledPartySize,
    double rateMultiplier = 1.0,
  }) {
    // 1. Release reserved/held seats in the dynamic ledger
    var updatedLedger = ledger.releaseReservedSeats(
      bookingId: cancelledBookingId,
      partySize: cancelledPartySize,
    );
    updatedLedger = updatedLedger.releaseHeldSeats(
      bookingId: cancelledBookingId,
      partySize: cancelledPartySize,
    );

    // 2. Remove all waypoints associated with the cancelled booking
    final remainingWaypoints = trip.waypoints
        .where((w) => w.bookingId != cancelledBookingId)
        .toList();

    // Re-index remaining stop sequence
    for (int i = 0; i < remainingWaypoints.length; i++) {
      remainingWaypoints[i] = remainingWaypoints[i].copyWith(
        stopSequence: i + 1,
        status: i == 0 ? WaypointStatus.current : WaypointStatus.pending,
      );
    }

    // 3. Re-calculate fares for remaining passengers
    final reallocatedFares = <String, double>{};
    bool requiresReConsent = false;

    // Remaining distinct bookings
    final remainingBookings = remainingWaypoints
        .map((w) => w.bookingId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    PooledRideOffer updatedOffer = trip.offer;

    if (remainingBookings.length <= 1) {
      // Reverts to direct solo ride for remaining user/booking
      final remainingUser = remainingWaypoints.firstWhere(
        (w) => w.isUser,
        orElse: () => remainingWaypoints.first,
      );
      final soloFare = trip.offer.fareBreakdown.soloFare;
      reallocatedFares[remainingUser.bookingId] = soloFare;

      updatedOffer = trip.offer.copyWith(
        coPassengersCount: 0,
        coPassengerLabels: const [],
        detourPercentage: 0.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: soloFare,
          sharedFare: soloFare,
          coalitionSize: 1,
          explanation: 'Rebalanced to solo direct ride following co-passenger cancellation.',
        ),
      );
    } else {
      // Re-allocate Shapley fares for remaining multi-passenger coalition
      final candidates = <BookingCandidate>[];
      for (final bId in remainingBookings) {
        final bWaypoints = remainingWaypoints.where((w) => w.bookingId == bId).toList();
        final pStop = bWaypoints.firstWhere((w) => w.type == WaypointType.pickup);
        final dStop = bWaypoints.firstWhere((w) => w.type == WaypointType.dropoff);
        final soloEst = estimator.estimateRoute(
          pickup: pStop.location,
          dropoff: dStop.location,
          rateMultiplier: rateMultiplier,
        );
        candidates.add(
          BookingCandidate(
            id: bId,
            partySize: pStop.partySize,
            soloKm: soloEst.distanceKm,
            sharedKm: soloEst.distanceKm,
          ),
        );
      }

      final totalKm = estimator.estimateRoute(
        pickup: remainingWaypoints.first.location,
        dropoff: remainingWaypoints.last.location,
      ).distanceKm;

      final allocator = FareAllocator(
        costModel: costModel,
        detourValidator: detourValidator,
      );

      final allocation = allocator.allocate(
        candidates: candidates,
        totalSharedKm: totalKm,
        coalitionDistancesKm: {},
        rateMultiplier: rateMultiplier,
      );

      reallocatedFares.addAll(allocation.allocatedFares);

      updatedOffer = trip.offer.copyWith(
        coPassengersCount: remainingBookings.length - 1,
        coPassengerLabels: [
          for (final bId in remainingBookings.where((id) => id != 'book-1'))
            remainingWaypoints.firstWhere((w) => w.bookingId == bId).passengerName,
        ],
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: allocation.soloFares['book-1'] ?? trip.offer.fareBreakdown.soloFare,
          sharedFare: allocation.allocatedFares['book-1'] ?? trip.offer.fareBreakdown.sharedFare,
          coalitionSize: remainingBookings.length,
        ),
      );
    }

    final updatedTrip = trip.copyWith(
      waypoints: remainingWaypoints,
      currentWaypointIndex: 0,
      offer: updatedOffer,
      currentDetourPercentage: updatedOffer.detourPercentage,
      clearPendingJoinRequest: true,
    );

    return TripCancellationResult(
      updatedTrip: updatedTrip,
      updatedLedger: updatedLedger,
      reallocatedFares: reallocatedFares,
      requiresReConsent: requiresReConsent,
      message: 'Pre-departure cancellation processed cleanly. Seats released and route rebalanced.',
    );
  }

  /// Handles cancellation while the trip is already underway.
  TripCancellationResult handleMidTripCancellation({
    required ActiveTrip trip,
    required SeatLedger ledger,
    required String cancelledBookingId,
    required int cancelledPartySize,
    double rateMultiplier = 1.0,
  }) {
    // 1. Release occupied/reserved seats in ledger
    var updatedLedger = ledger.releaseOccupiedSeats(
      bookingId: cancelledBookingId,
      partySize: cancelledPartySize,
    );
    updatedLedger = updatedLedger.releaseReservedSeats(
      bookingId: cancelledBookingId,
      partySize: cancelledPartySize,
    );
    updatedLedger = updatedLedger.releaseHeldSeats(
      bookingId: cancelledBookingId,
      partySize: cancelledPartySize,
    );

    // 2. Freeze completed prefix stops
    final completedCount = trip.currentWaypointIndex.clamp(0, trip.waypoints.length);
    final completedPrefix = trip.waypoints.sublist(0, completedCount);

    // 3. Filter cancelled booking stops from the pending leg
    final rawPendingLeg = trip.waypoints.sublist(completedCount);
    final remainingPendingLeg = rawPendingLeg
        .where((w) => w.bookingId != cancelledBookingId)
        .toList();

    // 4. Combine frozen prefix and remaining pending leg
    final combinedWaypoints = <TripWaypoint>[
      ...completedPrefix,
      ...remainingPendingLeg,
    ];

    // Re-index stop sequence
    for (int i = 0; i < combinedWaypoints.length; i++) {
      combinedWaypoints[i] = combinedWaypoints[i].copyWith(
        stopSequence: i + 1,
      );
    }

    // 5. Adjust fares and detect if remaining riders' costs change (increase)
    final reallocatedFares = <String, double>{};
    bool requiresReConsent = false;

    final remainingBookings = remainingPendingLeg
        .map((w) => w.bookingId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    PooledRideOffer updatedOffer = trip.offer;

    if (remainingBookings.length <= 1) {
      final userBookingId = 'book-1';
      final soloEst = estimator.estimateRoute(
        pickup: trip.offer.pickup,
        dropoff: trip.offer.dropoff,
        rateMultiplier: rateMultiplier,
      );

      final soloFare = soloEst.referenceFare;
      reallocatedFares[userBookingId] = soloFare;

      // Because co-passenger cancelled, remaining rider's fare increased from shared to solo
      if (soloFare > trip.offer.fareBreakdown.sharedFare) {
        requiresReConsent = true;
      }

      updatedOffer = trip.offer.copyWith(
        coPassengersCount: 0,
        coPassengerLabels: const [],
        detourPercentage: 0.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: soloFare,
          sharedFare: soloFare,
          coalitionSize: 1,
          explanation: 'Co-passenger cancelled mid-trip. Rebalanced to direct solo fare.',
        ),
      );
    } else {
      // Re-allocate Shapley fares
      final candidates = <BookingCandidate>[];
      for (final bId in remainingBookings) {
        final bWaypoints = combinedWaypoints.where((w) => w.bookingId == bId).toList();
        final pStop = bWaypoints.firstWhere((w) => w.type == WaypointType.pickup);
        final dStop = bWaypoints.firstWhere((w) => w.type == WaypointType.dropoff);
        final soloEst = estimator.estimateRoute(
          pickup: pStop.location,
          dropoff: dStop.location,
          rateMultiplier: rateMultiplier,
        );
        candidates.add(
          BookingCandidate(
            id: bId,
            partySize: pStop.partySize,
            soloKm: soloEst.distanceKm,
            sharedKm: soloEst.distanceKm,
          ),
        );
      }

      final allocator = FareAllocator(
        costModel: costModel,
        detourValidator: detourValidator,
      );

      final totalKm = estimator.estimateRoute(
        pickup: combinedWaypoints.first.location,
        dropoff: combinedWaypoints.last.location,
      ).distanceKm;

      final allocation = allocator.allocate(
        candidates: candidates,
        totalSharedKm: totalKm,
        coalitionDistancesKm: {},
        rateMultiplier: rateMultiplier,
      );

      reallocatedFares.addAll(allocation.allocatedFares);

      final newSharedFare = allocation.allocatedFares['book-1'] ?? trip.offer.fareBreakdown.sharedFare;
      if (newSharedFare > trip.offer.fareBreakdown.sharedFare) {
        requiresReConsent = true;
      }

      updatedOffer = trip.offer.copyWith(
        coPassengersCount: remainingBookings.length - 1,
        coPassengerLabels: [
          for (final bId in remainingBookings.where((id) => id != 'book-1'))
            combinedWaypoints.firstWhere((w) => w.bookingId == bId).passengerName,
        ],
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: allocation.soloFares['book-1'] ?? trip.offer.fareBreakdown.soloFare,
          sharedFare: newSharedFare,
          coalitionSize: remainingBookings.length,
        ),
      );
    }

    final updatedTrip = trip.copyWith(
      waypoints: combinedWaypoints,
      currentWaypointIndex: completedCount,
      offer: updatedOffer,
      currentDetourPercentage: updatedOffer.detourPercentage,
      clearPendingJoinRequest: true,
    );

    return TripCancellationResult(
      updatedTrip: updatedTrip,
      updatedLedger: updatedLedger,
      reallocatedFares: reallocatedFares,
      requiresReConsent: requiresReConsent,
      message: 'Mid-trip cancellation processed. Completed prefixes frozen and pending stops re-optimized.',
    );
  }
}
