import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';

enum PassengerBookingStatus {
  planning,
  batchWaiting,
  offerReceived,
  tripActive,
  tripCompleted,
}

class PassengerState extends Equatable {
  const PassengerState({
    this.pickup,
    this.dropoff,
    this.estimate,
    this.partySize = 1,
    this.status = PassengerBookingStatus.planning,
    this.countdownSeconds = 15,
    this.totalCountdownSeconds = 15,
    this.activeOffer,
    this.offerExpirySeconds = 20,
    this.activeTrip,
    this.activeReceipt,
    this.tripHistory = const [],
    this.isViewingHistory = false,
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final SoloRouteEstimate? estimate;
  final int partySize;
  final PassengerBookingStatus status;
  final int countdownSeconds;
  final int totalCountdownSeconds;
  final PooledRideOffer? activeOffer;
  final int offerExpirySeconds;
  final ActiveTrip? activeTrip;
  final TripReceipt? activeReceipt;
  final List<TripReceipt> tripHistory;
  final bool isViewingHistory;

  PassengerState copyWith({
    PuneLocation? pickup,
    PuneLocation? dropoff,
    SoloRouteEstimate? estimate,
    int? partySize,
    PassengerBookingStatus? status,
    int? countdownSeconds,
    int? totalCountdownSeconds,
    PooledRideOffer? activeOffer,
    bool clearActiveOffer = false,
    int? offerExpirySeconds,
    ActiveTrip? activeTrip,
    bool clearActiveTrip = false,
    TripReceipt? activeReceipt,
    bool clearActiveReceipt = false,
    List<TripReceipt>? tripHistory,
    bool? isViewingHistory,
  }) {
    return PassengerState(
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      estimate: estimate ?? this.estimate,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalCountdownSeconds:
          totalCountdownSeconds ?? this.totalCountdownSeconds,
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
      offerExpirySeconds: offerExpirySeconds ?? this.offerExpirySeconds,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      activeReceipt:
          clearActiveReceipt ? null : (activeReceipt ?? this.activeReceipt),
      tripHistory: tripHistory ?? this.tripHistory,
      isViewingHistory: isViewingHistory ?? this.isViewingHistory,
    );
  }

  @override
  List<Object?> get props => [
        pickup,
        dropoff,
        estimate,
        partySize,
        status,
        countdownSeconds,
        totalCountdownSeconds,
        activeOffer,
        offerExpirySeconds,
        activeTrip,
        activeReceipt,
        tripHistory,
        isViewingHistory,
      ];
}
