import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

enum PassengerBookingStatus {
  planning,
  batchWaiting,
  offerReceived,
  batchOutcome,
  tripActive,
  tripCompleted,
}

class PassengerState extends Equatable {
  const PassengerState({
    this.pickup,
    this.dropoff,
    this.estimate,
    this.partySize = 1,
    this.selectedTier = VehicleTier.car,
    this.status = PassengerBookingStatus.planning,
    this.countdownSeconds = 15,
    this.totalCountdownSeconds = 15,
    this.batchWindowSeconds = 15,
    this.matchingOutcome,
    this.activeOffer,
    this.offerExpirySeconds = 20,
    this.activeTrip,
    this.activeReceipt,
    this.tripHistory = const [],
    this.isViewingHistory = false,
    this.isPinConfirmationMode = false,
    this.pinTargetIsPickup = true,
    this.pendingPinLocation,
    this.consentCountdownSeconds = 30,
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final SoloRouteEstimate? estimate;
  final int partySize;
  final VehicleTier selectedTier;
  final PassengerBookingStatus status;
  final int countdownSeconds;
  final int totalCountdownSeconds;
  final int batchWindowSeconds;
  final BatchMatchingOutcome? matchingOutcome;
  final PooledRideOffer? activeOffer;
  final int offerExpirySeconds;
  final ActiveTrip? activeTrip;
  final TripReceipt? activeReceipt;
  final List<TripReceipt> tripHistory;
  final bool isViewingHistory;
  final bool isPinConfirmationMode;
  final bool pinTargetIsPickup;
  final PuneLocation? pendingPinLocation;
  final int consentCountdownSeconds;

  PassengerState copyWith({
    PuneLocation? pickup,
    PuneLocation? dropoff,
    SoloRouteEstimate? estimate,
    int? partySize,
    VehicleTier? selectedTier,
    PassengerBookingStatus? status,
    int? countdownSeconds,
    int? totalCountdownSeconds,
    int? batchWindowSeconds,
    BatchMatchingOutcome? matchingOutcome,
    bool clearMatchingOutcome = false,
    PooledRideOffer? activeOffer,
    bool clearActiveOffer = false,
    int? offerExpirySeconds,
    ActiveTrip? activeTrip,
    bool clearActiveTrip = false,
    TripReceipt? activeReceipt,
    bool clearActiveReceipt = false,
    List<TripReceipt>? tripHistory,
    bool? isViewingHistory,
    bool? isPinConfirmationMode,
    bool? pinTargetIsPickup,
    PuneLocation? pendingPinLocation,
    bool clearPendingPinLocation = false,
    int? consentCountdownSeconds,
  }) {
    return PassengerState(
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      estimate: estimate ?? this.estimate,
      partySize: partySize ?? this.partySize,
      selectedTier: selectedTier ?? this.selectedTier,
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalCountdownSeconds:
          totalCountdownSeconds ?? this.totalCountdownSeconds,
      batchWindowSeconds: batchWindowSeconds ?? this.batchWindowSeconds,
      matchingOutcome: clearMatchingOutcome
          ? null
          : (matchingOutcome ?? this.matchingOutcome),
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
      offerExpirySeconds: offerExpirySeconds ?? this.offerExpirySeconds,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      activeReceipt:
          clearActiveReceipt ? null : (activeReceipt ?? this.activeReceipt),
      tripHistory: tripHistory ?? this.tripHistory,
      isViewingHistory: isViewingHistory ?? this.isViewingHistory,
      isPinConfirmationMode:
          isPinConfirmationMode ?? this.isPinConfirmationMode,
      pinTargetIsPickup: pinTargetIsPickup ?? this.pinTargetIsPickup,
      pendingPinLocation: clearPendingPinLocation
          ? null
          : (pendingPinLocation ?? this.pendingPinLocation),
      consentCountdownSeconds:
          consentCountdownSeconds ?? this.consentCountdownSeconds,
    );
  }

  @override
  List<Object?> get props => [
        pickup,
        dropoff,
        estimate,
        partySize,
        selectedTier,
        status,
        countdownSeconds,
        totalCountdownSeconds,
        batchWindowSeconds,
        matchingOutcome,
        activeOffer,
        offerExpirySeconds,
        activeTrip,
        activeReceipt,
        tripHistory,
        isViewingHistory,
        isPinConfirmationMode,
        pinTargetIsPickup,
        pendingPinLocation,
        consentCountdownSeconds,
      ];
}
