import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/engine/in_flight_rebalancing_engine.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/repositories/trip_history_repository.dart';

class PassengerCubit extends Cubit<PassengerState> {
  PassengerCubit({
    RouteEstimatorService estimator = const RouteEstimatorService(),
    TripHistoryRepository? historyRepository,
    PuneLocation? initialPickup = PuneLandmarks.kothrud,
    PuneLocation? initialDropoff = PuneLandmarks.hinjawadiPhase1,
    VehicleTier initialTier = VehicleTier.auto,
    InFlightRebalancingEngine? rebalancer,
  })  : _estimator = estimator,
        _rebalancer = rebalancer ?? InFlightRebalancingEngine(estimator: estimator),
        _historyRepository =
            historyRepository ?? LocalTripHistoryRepository(),
        super(PassengerState(
          pickup: initialPickup,
          dropoff: initialDropoff,
          selectedTier: initialTier,
          estimate: (initialPickup != null && initialDropoff != null)
              ? estimator.estimateRoute(
                  pickup: initialPickup,
                  dropoff: initialDropoff,
                  rateMultiplier: initialTier.rateMultiplier,
                )
              : null,
        )) {
    loadTripHistory();
  }

  final RouteEstimatorService _estimator;
  final InFlightRebalancingEngine _rebalancer;
  final TripHistoryRepository _historyRepository;
  Timer? _countdownTimer;
  Timer? _offerExpiryTimer;
  Timer? _consentCountdownTimer;

  static final List<BatchVehicle> _defaultFleet = [
    BatchVehicle(
      id: 'v-auto-1',
      model: 'Bajaj RE EV',
      licensePlate: 'MH-12-AU-1001',
      driverName: 'Santosh T.',
      driverRating: 4.85,
      tier: VehicleTier.auto,
      currentLocation: PuneLandmarks.kothrud,
    ),
    BatchVehicle(
      id: 'v-car-1',
      model: 'Tata Tigor EV',
      licensePlate: 'MH-12-RN-4821',
      driverName: 'Suresh K.',
      driverRating: 4.90,
      tier: VehicleTier.car,
      currentLocation: PuneLandmarks.kothrud,
    ),
    BatchVehicle(
      id: 'v-carxl-1',
      model: 'Toyota Innova Hycross',
      licensePlate: 'MH-12-XL-9009',
      driverName: 'Mahesh P.',
      driverRating: 4.95,
      tier: VehicleTier.carXl,
      currentLocation: PuneLandmarks.kothrud,
    ),
  ];

  List<BatchRideRequest> _defaultSyntheticQueue(
    VehicleTier tier,
    PuneLocation pickup,
    PuneLocation dropoff,
  ) {
    const bavdhan = PuneLocation(
      name: 'Bavdhan Flyover',
      latitude: 18.5126,
      longitude: 73.7712,
      landmarkNote: 'NDA Road Bypass',
    );
    const baner = PuneLocation(
      name: 'Baner High Street',
      latitude: 18.5590,
      longitude: 73.7788,
      landmarkNote: 'Baner Road Corridor',
    );

    return [
      BatchRideRequest(
        id: 'req-copassenger-1',
        passengerName: 'Priya',
        pickup: bavdhan,
        dropoff: dropoff,
        partySize: 1,
        tier: tier,
      ),
      BatchRideRequest(
        id: 'req-copassenger-2',
        passengerName: 'Rohan',
        pickup: baner,
        dropoff: dropoff,
        partySize: 1,
        tier: tier,
      ),
    ];
  }

  Future<void> loadTripHistory() async {
    final history = await _historyRepository.getTripHistory();
    emit(state.copyWith(tripHistory: history));
  }

  void toggleTripHistory(bool show) {
    emit(state.copyWith(isViewingHistory: show));
  }

  void setVehicleTier(VehicleTier tier) {
    var partySize = state.partySize;
    if (partySize > tier.capacity) {
      partySize = tier.capacity;
    }

    final newEstimate = _recalculateEstimate(
      pickup: state.pickup,
      dropoff: state.dropoff,
      tier: tier,
    );

    emit(state.copyWith(
      selectedTier: tier,
      partySize: partySize,
      estimate: newEstimate,
    ));
  }

  void setPickup(PuneLocation location) {
    final newDropoff = state.dropoff;
    SoloRouteEstimate? newEstimate;

    if (newDropoff != null && location != newDropoff) {
      newEstimate = _estimator.estimateRoute(
        pickup: location,
        dropoff: newDropoff,
        rateMultiplier: state.selectedTier.rateMultiplier,
      );
    }

    emit(state.copyWith(
      pickup: location,
      estimate: newEstimate,
    ));
  }

  void setDropoff(PuneLocation location) {
    final currentPickup = state.pickup;
    SoloRouteEstimate? newEstimate;

    if (currentPickup != null && currentPickup != location) {
      newEstimate = _estimator.estimateRoute(
        pickup: currentPickup,
        dropoff: location,
        rateMultiplier: state.selectedTier.rateMultiplier,
      );
    }

    emit(state.copyWith(
      dropoff: location,
      estimate: newEstimate,
    ));
  }

  void setPartySize(int seats, {bool allowTierUpgrade = false}) {
    if (seats < 1 || seats > 6) return;
    var tier = state.selectedTier;

    if (seats > tier.capacity) {
      if (allowTierUpgrade) {
        if (seats <= VehicleTier.car.capacity) {
          tier = VehicleTier.car;
        } else {
          tier = VehicleTier.carXl;
        }
      } else {
        return;
      }
    }

    final newEstimate = _recalculateEstimate(
      pickup: state.pickup,
      dropoff: state.dropoff,
      tier: tier,
    );

    emit(state.copyWith(
      partySize: seats,
      selectedTier: tier,
      estimate: newEstimate,
    ));
  }

  void incrementPartySize({bool allowTierUpgrade = false}) {
    if (state.partySize < 6) {
      setPartySize(state.partySize + 1, allowTierUpgrade: allowTierUpgrade);
    }
  }

  void decrementPartySize() {
    if (state.partySize > 1) {
      setPartySize(state.partySize - 1);
    }
  }

  void setBatchWindowSeconds(int seconds) {
    final clamped = seconds.clamp(15, 90);
    emit(state.copyWith(batchWindowSeconds: clamped));
  }

  void swapLocations() {
    final oldPickup = state.pickup;
    final oldDropoff = state.dropoff;

    if (oldPickup == null || oldDropoff == null) return;

    final newEstimate = _estimator.estimateRoute(
      pickup: oldDropoff,
      dropoff: oldPickup,
      rateMultiplier: state.selectedTier.rateMultiplier,
    );

    emit(state.copyWith(
      pickup: oldDropoff,
      dropoff: oldPickup,
      estimate: newEstimate,
    ));
  }

  void startBatchWaiting({
    int? durationSeconds,
    List<BatchRideRequest>? syntheticQueue,
    List<BatchVehicle>? fleet,
    bool allowSoloFallback = true,
  }) {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();

    final totalDuration = durationSeconds ?? state.batchWindowSeconds;

    emit(state.copyWith(
      status: PassengerBookingStatus.batchWaiting,
      countdownSeconds: totalDuration,
      totalCountdownSeconds: totalDuration,
      clearActiveOffer: true,
      clearActiveTrip: true,
      clearActiveReceipt: true,
      clearMatchingOutcome: true,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        emit(state.copyWith(
          countdownSeconds: state.countdownSeconds - 1,
        ));
      } else {
        timer.cancel();
        _evaluateBatchMatch(
          syntheticQueue: syntheticQueue,
          fleet: fleet,
          allowSoloFallback: allowSoloFallback,
        );
      }
    });
  }

  void _evaluateBatchMatch({
    List<BatchRideRequest>? syntheticQueue,
    List<BatchVehicle>? fleet,
    bool allowSoloFallback = true,
  }) {
    final pickup = state.pickup ?? PuneLandmarks.kothrud;
    final dropoff = state.dropoff ?? PuneLandmarks.hinjawadiPhase1;
    final tier = state.selectedTier;

    final targetRequest = BatchRideRequest(
      id: 'req-user-${DateTime.now().millisecondsSinceEpoch}',
      passengerName: 'You',
      pickup: pickup,
      dropoff: dropoff,
      partySize: state.partySize,
      tier: tier,
    );

    final queue = syntheticQueue ?? _defaultSyntheticQueue(tier, pickup, dropoff);
    final vehicles = fleet ?? _defaultFleet;

    final matcher = CombinatorialBatchMatcher(estimator: _estimator);
    final outcome = matcher.match(
      targetRequest: targetRequest,
      queuedRequests: queue,
      availableVehicles: vehicles,
      allowSoloFallback: allowSoloFallback,
    );

    if (outcome is MatchFoundOutcome) {
      emit(state.copyWith(matchingOutcome: outcome));
      receiveOffer(outcome.offer);
    } else {
      emit(state.copyWith(
        status: PassengerBookingStatus.batchOutcome,
        matchingOutcome: outcome,
        countdownSeconds: 0,
      ));
    }
  }

  void setMatchingOutcome(BatchMatchingOutcome outcome) {
    _countdownTimer?.cancel();
    if (outcome is MatchFoundOutcome) {
      emit(state.copyWith(matchingOutcome: outcome));
      receiveOffer(outcome.offer);
    } else {
      emit(state.copyWith(
        status: PassengerBookingStatus.batchOutcome,
        matchingOutcome: outcome,
        countdownSeconds: 0,
      ));
    }
  }

  void cancelBatchWaiting() {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      countdownSeconds: state.batchWindowSeconds,
      clearActiveOffer: true,
      clearActiveTrip: true,
      clearActiveReceipt: true,
      clearMatchingOutcome: true,
    ));
  }

  void receiveOffer(PooledRideOffer offer) {
    if (offer.detourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: offer.detourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }

    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();

    emit(state.copyWith(
      status: PassengerBookingStatus.offerReceived,
      activeOffer: offer,
      countdownSeconds: 0,
      offerExpirySeconds: offer.offerExpirySeconds,
      clearActiveTrip: true,
      clearActiveReceipt: true,
    ));

    _offerExpiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.offerExpirySeconds > 1) {
        emit(state.copyWith(
          offerExpirySeconds: state.offerExpirySeconds - 1,
        ));
      } else {
        timer.cancel();
        // Offer expired: reset back to planning sheet
        emit(state.copyWith(
          status: PassengerBookingStatus.planning,
          clearActiveOffer: true,
          clearActiveTrip: true,
          clearActiveReceipt: true,
          clearMatchingOutcome: true,
          offerExpirySeconds: 20,
        ));
      }
    });
  }

  void acceptOffer() {
    final currentOffer = state.activeOffer;
    if (currentOffer == null) return;

    if (currentOffer.detourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: currentOffer.detourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }

    _offerExpiryTimer?.cancel();
    final activeTrip = ActiveTrip.fromOffer(offer: currentOffer);
    emit(state.copyWith(
      status: PassengerBookingStatus.tripActive,
      activeTrip: activeTrip,
      clearActiveReceipt: true,
    ));
  }

  void acceptSoloDirectRide(SoloDirectRideOutcome soloOutcome) {
    final activeTrip = ActiveTrip.fromOffer(
      offer: PooledRideOffer(
        offerId: 'offer-solo-${DateTime.now().millisecondsSinceEpoch}',
        vehicleModel: soloOutcome.vehicle.model,
        licensePlate: soloOutcome.vehicle.licensePlate,
        driverName: soloOutcome.vehicle.driverName,
        driverRating: soloOutcome.vehicle.driverRating,
        pickup: soloOutcome.request.pickup,
        dropoff: soloOutcome.request.dropoff,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes:
            _estimator.calculateDurationMinutes(soloOutcome.distanceKm),
        coPassengersCount: 0,
        coPassengerLabels: const [],
        detourPercentage: 0.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: soloOutcome.soloFare,
          sharedFare: soloOutcome.soloFare,
          coalitionSize: 1,
          explanation: 'Solo direct ride dispatched at tier rate multiplier.',
        ),
      ),
    );

    emit(state.copyWith(
      status: PassengerBookingStatus.tripActive,
      activeTrip: activeTrip,
      clearActiveOffer: true,
      clearMatchingOutcome: true,
      clearActiveReceipt: true,
    ));
  }

  void dismissBatchOutcome() {
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      clearMatchingOutcome: true,
      clearActiveOffer: true,
      clearActiveTrip: true,
      clearActiveReceipt: true,
    ));
  }

  void declineOffer() {
    _offerExpiryTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      clearActiveOffer: true,
      clearActiveTrip: true,
      clearActiveReceipt: true,
      clearMatchingOutcome: true,
      offerExpirySeconds: 20,
    ));
  }

  void advanceTripStep() {
    final trip = state.activeTrip;
    if (trip == null) return;

    if (trip.currentWaypointIndex >= trip.waypoints.length - 1) {
      completeActiveTrip();
      return;
    }

    emit(state.copyWith(
      activeTrip: trip.advanceWaypoint(),
    ));
  }

  Future<void> completeActiveTrip() async {
    final trip = state.activeTrip;
    final offer = trip?.offer ?? state.activeOffer;
    if (offer == null) return;

    final soloFare = offer.fareBreakdown.soloFare;
    final finalFare = offer.fareBreakdown.sharedFare;
    final detour =
        trip?.currentDetourPercentage ?? offer.detourPercentage;
    final distanceKm = state.estimate?.distanceKm ?? 14.0;

    final kmSaved = (distanceKm * 0.6).clamp(1.0, 50.0);
    final co2Saved = kmSaved * 0.12;
    final fuelSaved = (kmSaved / 15.0 * 100).round() / 100.0;
    final farePaise = (finalFare * 100).round();
    final driverPayoutPaise = ((finalFare * 0.85) * 100).round();

    final receipt = TripReceipt(
      receiptId: 'rcpt-${DateTime.now().millisecondsSinceEpoch}',
      tripId: trip?.tripId ?? 'trip-${offer.offerId}',
      vehicleModel: offer.vehicleModel,
      licensePlate: offer.licensePlate,
      driverName: offer.driverName,
      pickup: offer.pickup,
      dropoff: offer.dropoff,
      completedAt: DateTime.now(),
      soloReferenceFare: soloFare,
      finalPayableFare: finalFare,
      farePaise: farePaise,
      driverPayoutPaise: driverPayoutPaise,
      paymentStatus: PaymentStatus.unpaid,
      finalDetourPercentage: detour,
      environmentalImpact: EnvironmentalImpact(
        vehicleKmSaved: (kmSaved * 10).round() / 10.0,
        co2SavedKg: (co2Saved * 100).round() / 100.0,
        fuelSavedLitres: fuelSaved,
      ),
      coalitionAudits: [
        CoalitionMemberAudit(
          passengerName: 'You',
          isUser: true,
          soloFare: soloFare,
          marginalContribution: (soloFare * 0.45).roundToDouble(),
          shapleyFairShare: finalFare,
        ),
        for (final coPassenger in offer.coPassengerLabels)
          CoalitionMemberAudit(
            passengerName: coPassenger.split(' ').first,
            soloFare: (soloFare * 0.85).roundToDouble(),
            marginalContribution: (soloFare * 0.35).roundToDouble(),
            shapleyFairShare: (soloFare * 0.60).roundToDouble(),
          ),
      ],
    );

    await _historyRepository.saveReceipt(receipt);
    final updatedHistory = [
      receipt,
      ...state.tripHistory.where((r) => r.receiptId != receipt.receiptId),
    ];

    emit(state.copyWith(
      status: PassengerBookingStatus.tripCompleted,
      activeReceipt: receipt,
      tripHistory: updatedHistory,
      clearActiveTrip: true,
      clearActiveOffer: true,
      clearMatchingOutcome: true,
    ));
  }

  Future<void> settleReceiptPayment(TripReceipt updatedReceipt) async {
    await _historyRepository.saveReceipt(updatedReceipt);
    final updatedHistory = [
      updatedReceipt,
      ...state.tripHistory.where((r) => r.receiptId != updatedReceipt.receiptId),
    ];

    emit(state.copyWith(
      activeReceipt: updatedReceipt,
      tripHistory: updatedHistory,
    ));
  }

  void dismissReceipt() {
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      clearActiveReceipt: true,
      clearActiveTrip: true,
      clearActiveOffer: true,
      clearMatchingOutcome: true,
    ));
  }

  void requestMidTripJoin(MidTripJoinRequest joinRequest) {
    if (joinRequest.newDetourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: joinRequest.newDetourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }
    final trip = state.activeTrip;
    if (trip == null) return;

    _consentCountdownTimer?.cancel();

    final countdown = joinRequest.secondsRemaining;
    emit(state.copyWith(
      activeTrip: trip.copyWith(pendingJoinRequest: joinRequest),
      consentCountdownSeconds: countdown,
    ));

    _consentCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.consentCountdownSeconds > 1) {
        final nextSec = state.consentCountdownSeconds - 1;
        final currentTrip = state.activeTrip;
        final currentReq = currentTrip?.pendingJoinRequest;

        emit(state.copyWith(
          consentCountdownSeconds: nextSec,
          activeTrip: currentReq != null
              ? currentTrip!.copyWith(
                  pendingJoinRequest: currentReq.copyWith(secondsRemaining: nextSec),
                )
              : currentTrip,
        ));
      } else {
        timer.cancel();
        simulateConsentTimeout();
      }
    });
  }

  void simulateConsentTimeout() {
    _consentCountdownTimer?.cancel();
    final trip = state.activeTrip;
    if (trip == null) return;

    emit(state.copyWith(
      activeTrip: trip.copyWith(clearPendingJoinRequest: true),
      consentCountdownSeconds: 30,
    ));
  }

  void approveMidTripJoin() {
    _consentCountdownTimer?.cancel();
    final trip = state.activeTrip;
    final joinReq = trip?.pendingJoinRequest;
    if (trip == null || joinReq == null) return;

    emit(state.copyWith(
      activeTrip: trip.applyMidTripJoin(joinReq),
      consentCountdownSeconds: 30,
    ));
  }

  void rejectMidTripJoin() {
    _consentCountdownTimer?.cancel();
    final trip = state.activeTrip;
    if (trip == null) return;

    emit(state.copyWith(
      activeTrip: trip.copyWith(clearPendingJoinRequest: true),
      consentCountdownSeconds: 30,
    ));
  }

  void cancelActiveTripPreDeparture() {
    _consentCountdownTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      clearActiveTrip: true,
      clearActiveOffer: true,
      clearMatchingOutcome: true,
      clearActiveReceipt: true,
      consentCountdownSeconds: 30,
    ));
  }

  void cancelCoPassengerMidTrip({
    required String bookingId,
    int partySize = 1,
  }) {
    final trip = state.activeTrip;
    if (trip == null) return;

    final dummyLedger = SeatLedger.empty(capacity: 4)
        .boardSeats(bookingId: 'book-1', partySize: trip.offer.partySize)
        .boardSeats(bookingId: bookingId, partySize: partySize);

    final result = _rebalancer.handleMidTripCancellation(
      trip: trip,
      ledger: dummyLedger,
      cancelledBookingId: bookingId,
      cancelledPartySize: partySize,
      rateMultiplier: state.selectedTier.rateMultiplier,
    );

    emit(state.copyWith(
      activeTrip: result.updatedTrip,
    ));
  }

  void startPinConfirmationMode({required bool isPickup}) {
    emit(state.copyWith(
      isPinConfirmationMode: true,
      pinTargetIsPickup: isPickup,
      pendingPinLocation: isPickup ? state.pickup : state.dropoff,
    ));
  }

  void setPendingPinLocation(PuneLocation location) {
    emit(state.copyWith(pendingPinLocation: location));
  }

  void confirmMapPin(PuneLocation location) {
    if (state.pinTargetIsPickup) {
      setPickup(location);
    } else {
      setDropoff(location);
    }
    emit(state.copyWith(
      isPinConfirmationMode: false,
      clearPendingPinLocation: true,
    ));
  }

  void cancelPinConfirmationMode() {
    emit(state.copyWith(
      isPinConfirmationMode: false,
      clearPendingPinLocation: true,
    ));
  }

  SoloRouteEstimate? _recalculateEstimate({
    required PuneLocation? pickup,
    required PuneLocation? dropoff,
    required VehicleTier tier,
  }) {
    if (pickup == null || dropoff == null || pickup == dropoff) return null;
    return _estimator.estimateRoute(
      pickup: pickup,
      dropoff: dropoff,
      rateMultiplier: tier.rateMultiplier,
    );
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();
    _consentCountdownTimer?.cancel();
    return super.close();
  }
}
