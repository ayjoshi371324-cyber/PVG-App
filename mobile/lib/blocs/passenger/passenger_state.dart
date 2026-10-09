import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

enum PassengerBookingStatus {
  planning,
  batchWaiting,
  offerReceived,
  tripActive,
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
      ];
}
