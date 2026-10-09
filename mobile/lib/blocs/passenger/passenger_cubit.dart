import 'dart:async';
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
  Timer? _countdownTimer;

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

    emit(state.copyWith(
      status: PassengerBookingStatus.batchWaiting,
      countdownSeconds: durationSeconds,
      totalCountdownSeconds: durationSeconds,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        emit(state.copyWith(
          countdownSeconds: state.countdownSeconds - 1,
        ));
      } else {
        timer.cancel();
        emit(state.copyWith(
          status: PassengerBookingStatus.offerReceived,
          countdownSeconds: 0,
        ));
      }
    });
  }

  void cancelBatchWaiting() {
    _countdownTimer?.cancel();
    emit(state.copyWith(
      status: PassengerBookingStatus.planning,
      countdownSeconds: 15,
    ));
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
