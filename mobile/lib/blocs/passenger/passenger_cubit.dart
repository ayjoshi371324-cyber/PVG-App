import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
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
    if (seats < 1 || seats > 4) return;
    emit(state.copyWith(partySize: seats));
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
}
