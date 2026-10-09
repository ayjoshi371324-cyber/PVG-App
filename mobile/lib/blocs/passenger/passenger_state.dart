import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

enum PassengerBookingStatus {
  planning,
  batchWaiting,
  offerReceived,
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
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final SoloRouteEstimate? estimate;
  final int partySize;
  final PassengerBookingStatus status;
  final int countdownSeconds;
  final int totalCountdownSeconds;

  PassengerState copyWith({
    PuneLocation? pickup,
    PuneLocation? dropoff,
    SoloRouteEstimate? estimate,
    int? partySize,
    PassengerBookingStatus? status,
    int? countdownSeconds,
    int? totalCountdownSeconds,
  }) {
    return PassengerState(
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      estimate: estimate ?? this.estimate,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalCountdownSeconds: totalCountdownSeconds ?? this.totalCountdownSeconds,
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
      ];
}
