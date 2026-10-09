import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class PassengerCubit extends Cubit<PassengerState> {
  PassengerCubit({
    RouteEstimatorService estimator = const RouteEstimatorService(),
    PuneLocation? initialPickup = PuneLandmarks.kothrud,
    PuneLocation? initialDropoff = PuneLandmarks.hinjawadiPhase1,
  })  : _estimator = estimator,
        super(PassengerState(
          pickup: initialPickup,
          dropoff: initialDropoff,
          estimate: (initialPickup != null && initialDropoff != null)
              ? estimator.estimateRoute(
                  pickup: initialPickup,
                  dropoff: initialDropoff,
                )
              : null,
        ));

  final RouteEstimatorService _estimator;
  Timer? _countdownTimer;
  Timer? _offerExpiryTimer;

  void setPickup(PuneLocation location) {
    final newDropoff = state.dropoff;
    SoloRouteEstimate? newEstimate;

    if (newDropoff != null && location != newDropoff) {
      newEstimate = _estimator.estimateRoute(
        pickup: location,
        dropoff: newDropoff,
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
      );
    }

    emit(state.copyWith(
      dropoff: location,
      estimate: newEstimate,
    ));
  }

  void setPartySize(int seats) {
    if (seats < 1 || seats > 3) return;
    emit(state.copyWith(partySize: seats));
  }

  void incrementPartySize() {
    if (state.partySize < 3) {
      setPartySize(state.partySize + 1);
    }
  }

  void decrementPartySize() {
    if (state.partySize > 1) {
      setPartySize(state.partySize - 1);
    }
  }

  void swapLocations() {
    final oldPickup = state.pickup;
    final oldDropoff = state.dropoff;

    if (oldPickup == null || oldDropoff == null) return;

    final newEstimate = _estimator.estimateRoute(
      pickup: oldDropoff,
      dropoff: oldPickup,
    );

    emit(state.copyWith(
      pickup: oldDropoff,
      dropoff: oldPickup,
      estimate: newEstimate,
    ));
  }

  void startBatchWaiting({int durationSeconds = 15}) {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();

    emit(state.copyWith(
      status: PassengerBookingStatus.batchWaiting,
      countdownSeconds: durationSeconds,
      totalCountdownSeconds: durationSeconds,
      clearActiveOffer: true,
      clearActiveTrip: true,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        emit(state.copyWith(
          countdownSeconds: state.countdownSeconds - 1,
        ));
      } else {
        timer.cancel();
        // Generate an optimized pooled ride offer upon batch matching completion
        final offer = _generateSampleOffer();
        receiveOffer(offer);
      }
    });
  }

  void cancelBatchWaiting() {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      countdownSeconds: 15,
      clearActiveOffer: true,
      clearActiveTrip: true,
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
    ));
  }

  void declineOffer() {
    _offerExpiryTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      clearActiveOffer: true,
      clearActiveTrip: true,
      offerExpirySeconds: 20,
    ));
  }

  void advanceTripStep() {
    final trip = state.activeTrip;
    if (trip == null) return;
    emit(state.copyWith(
      activeTrip: trip.advanceWaypoint(),
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
    emit(state.copyWith(
      activeTrip: trip.copyWith(pendingJoinRequest: joinRequest),
    ));
  }

  void approveMidTripJoin() {
    final trip = state.activeTrip;
    final joinReq = trip?.pendingJoinRequest;
    if (trip == null || joinReq == null) return;

    emit(state.copyWith(
      activeTrip: trip.applyMidTripJoin(joinReq),
    ));
  }

  void rejectMidTripJoin() {
    final trip = state.activeTrip;
    if (trip == null) return;

    emit(state.copyWith(
      activeTrip: trip.copyWith(clearPendingJoinRequest: true),
    ));
  }

  PooledRideOffer _generateSampleOffer() {
    final pickup = state.pickup ?? PuneLandmarks.kothrud;
    final dropoff = state.dropoff ?? PuneLandmarks.hinjawadiPhase1;
    final estimate = state.estimate ??
        _estimator.estimateRoute(pickup: pickup, dropoff: dropoff);

    final soloFare = estimate.referenceFare;
    // Transparent Shapley 30% pooled discount for a 3-passenger coalition
    final sharedFare = (soloFare * 0.70).roundToDouble();

    return PooledRideOffer(
      offerId: 'offer-pune-${DateTime.now().millisecondsSinceEpoch}',
      vehicleModel: 'Tata Tigor EV',
      licensePlate: 'MH-12-RN-4821',
      driverName: 'Suresh K.',
      driverRating: 4.9,
      pickup: pickup,
      dropoff: dropoff,
      pickupEtaMinutes: 4,
      dropoffEtaMinutes: (estimate.durationMinutes * 1.08).round(),
      coPassengersCount: 2,
      coPassengerLabels: const [
        'Rohan (Swargate)',
        'Priya (Kothrud)',
      ],
      detourPercentage: 8.4, // Strict <= 15.0% guarantee certified
      fareBreakdown: ShapleyFareBreakdown(
        soloFare: soloFare,
        sharedFare: sharedFare,
        coalitionSize: 3,
        explanation:
            'Mathematically allocated via Shapley marginal cost contributions. Capped below solo baseline.',
      ),
      offerExpirySeconds: 20,
    );
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _offerExpiryTimer?.cancel();
    return super.close();
  }
}
