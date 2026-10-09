import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class PassengerState extends Equatable {
  const PassengerState({
    this.pickup,
    this.dropoff,
    this.estimate,
    this.partySize = 1,
    this.isSelectingPickup = false,
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final SoloRouteEstimate? estimate;
  final int partySize;
  final bool isSelectingPickup;

  PassengerState copyWith({
    PuneLocation? pickup,
    PuneLocation? dropoff,
    SoloRouteEstimate? estimate,
    int? partySize,
    bool? isSelectingPickup,
  }) {
    return PassengerState(
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      estimate: estimate ?? this.estimate,
      partySize: partySize ?? this.partySize,
      isSelectingPickup: isSelectingPickup ?? this.isSelectingPickup,
    );
  }

  @override
  List<Object?> get props => [
        pickup,
        dropoff,
        estimate,
        partySize,
        isSelectingPickup,
      ];
}
