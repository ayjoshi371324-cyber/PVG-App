import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/blocs/driver/driver_cubit.dart';
import 'package:ridepool_app/blocs/driver/driver_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/cabin_occupancy_gauge.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/otp_keypad_widget.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/turn_by_turn_manifest_card.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key, this.cubit});

  final DriverCubit? cubit;

  @override
  Widget build(BuildContext context) {
    DriverCubit? existingCubit;
    try {
      existingCubit = cubit ?? context.read<DriverCubit>();
    } catch (_) {
      existingCubit = null;
    }

    if (existingCubit != null) {
      return BlocProvider<DriverCubit>.value(
        value: existingCubit,
        child: const _DriverHomeContent(),
      );
    }

    return BlocProvider<DriverCubit>(
      create: (_) => DriverCubit(),
      child: const _DriverHomeContent(),
    );
  }
}

class _DriverHomeContent extends StatelessWidget {
  const _DriverHomeContent();

  List<LatLng> _computeRoutePolylines(List<DriverStop> stops) {
    if (stops.length < 2) return const [];
    const estimator = RouteEstimatorService();
    final points = <LatLng>[];

    for (int i = 0; i < stops.length - 1; i++) {
      final segEstimate = estimator.estimateRoute(
        pickup: stops[i].location,
        dropoff: stops[i + 1].location,
      );
      points.addAll(segEstimate.polylinePoints);
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, state) {
        final currentStop = state.currentStop;
        final isCompleted = state.isRouteCompleted;
        final polyline = _computeRoutePolylines(state.stops);

        return Scaffold(
          backgroundColor: UberColors.canvas,
          body: Stack(
            children: [
              // Background Interactive Pune Map with active driver route
              Positioned.fill(
                child: PuneMapWidget(
                  pickup: currentStop?.isPickup == true
                      ? currentStop!.location
                      : state.stops.first.location,
                  dropoff: currentStop?.isDropoff == true
                      ? currentStop!.location
                      : (currentStop != null ? currentStop.location : state.stops.last.location),
                  polylinePoints: polyline,
                ),
              ),

              // Upper Floating Bar: Vehicle & Shift status badges
              Positioned(
                top: UberSpacing.md,
                left: UberSpacing.lg,
                right: UberSpacing.lg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Assigned Vehicle Banner
                    UberCard(
                      variant: UberCardVariant.elevated,
                      padding: const EdgeInsets.symmetric(
                        horizontal: UberSpacing.md,
                        vertical: UberSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(UberSpacing.xs),
                            decoration: BoxDecoration(
                              color: UberColors.canvasSoft,
                              borderRadius: UberRadii.md,
                            ),
                            child: const Icon(
                              Icons.electric_car_rounded,
                              size: 20,
                              color: UberColors.ink,
                            ),
                          ),
                          const SizedBox(width: UberSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.vehicle.name,
                                  style: UberTypography.bodySmStrong,
                                ),
                                Text(
                                  '${state.vehicle.licensePlate} • ${state.vehicle.batteryPercentage}% ⚡',
                                  style: UberTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          MetricBadge(
                            label: 'Shift',
                            value: isCompleted ? 'Completed' : 'Online',
                            icon: Icons.circle,
                            variant: isCompleted
                                ? MetricBadgeVariant.dark
                                : MetricBadgeVariant.success,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Persistent Driver Bottom Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomDrawerSheet(
                  title: isCompleted
                      ? 'Route Completed'
                      : 'Next Stop: ${currentStop!.isPickup ? 'Pickup' : 'Dropoff'} ${currentStop.passengerName}',
                  subtitle: isCompleted
                      ? 'All scheduled pickups & dropoffs successfully finished'
                      : '${currentStop!.location.name} • ETA ${currentStop.etaMinutes} mins (${currentStop.distanceKm.toStringAsFixed(1)} km)',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Verification & Action Hero Card
                          UberCard(
                            variant: UberCardVariant.tinted,
                            padding: const EdgeInsets.all(UberSpacing.md),
                            child: isCompleted
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Shift Summary',
                                                style: UberTypography.caption,
                                              ),
                                              Text(
                                                'All Passengers Dropped Off',
                                                style: UberTypography.bodyMdStrong,
                                              ),
                                            ],
                                          ),
                                          const MetricBadge(
                                            label: '',
                                            value: 'Finished',
                                            variant: MetricBadgeVariant.success,
                                            compact: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: UberSpacing.md),
                                      PillButton(
                                        label: 'Reset Demo Route',
                                        size: PillButtonSize.large,
                                        fullWidth: true,
                                        icon: Icons.replay_rounded,
                                        onPressed: () {
                                          context.read<DriverCubit>().resetRoute();
                                        },
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Passenger Verification',
                                                style: UberTypography.caption,
                                              ),
                                              Text(
                                                '${currentStop!.passengerName} (${currentStop.seats} ${currentStop.seats == 1 ? 'Seat' : 'Seats'})',
                                                style: UberTypography.bodyMdStrong,
                                              ),
                                            ],
                                          ),
                                          MetricBadge(
                                            label: 'Code',
                                            value: currentStop.verificationCode,
                                            variant: MetricBadgeVariant.dark,
                                            compact: true,
                                          ),
                                        ],
                                      ),
                                      if (currentStop.isPickup) ...[
                                        const SizedBox(height: UberSpacing.sm),
                                        OtpKeypadWidget(
                                          enteredOtp: state.enteredOtp,
                                          isVerified: state.isCurrentStopVerified,
                                          isLocked: state.isStopLocked,
                                          errorMessage: state.otpErrorMessage,
                                          onDigitPressed: (digit) =>
                                              context.read<DriverCubit>().enterOtpDigit(digit),
                                          onDeletePressed: () =>
                                              context.read<DriverCubit>().deleteOtpDigit(),
                                          onClearPressed: () =>
                                              context.read<DriverCubit>().clearOtp(),
                                          onBypassPressed: () =>
                                              context.read<DriverCubit>().bypassOtp(),
                                          onManualOverride: () =>
                                              context.read<DriverCubit>().manualUnlockStop(),
                                        ),
                                      ],
                                      const SizedBox(height: UberSpacing.md),
                                      PillButton(
                                        label: currentStop.isPickup
                                            ? 'Confirm Passenger Boarded'
                                            : 'Confirm Passenger Dropped Off',
                                        size: PillButtonSize.large,
                                        fullWidth: true,
                                        variant: (currentStop.isDropoff || state.isCurrentStopVerified)
                                            ? PillButtonVariant.primary
                                            : PillButtonVariant.secondary,
                                        icon: currentStop.isPickup
                                            ? Icons.person_add_alt_1_rounded
                                            : Icons.check_circle_rounded,
                                        onPressed: (currentStop.isDropoff || state.isCurrentStopVerified)
                                            ? () {
                                                context.read<DriverCubit>().confirmCurrentStop();
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: UberSpacing.md),

                          // Interactive Cabin Occupancy Blueprint
                          CabinOccupancyGauge(
                            currentOccupancy: state.currentOccupancy,
                            maxCapacity: state.maxCapacity,
                            seats: state.cabinSeats,
                          ),

                          const SizedBox(height: UberSpacing.md),

                          // Turn-by-Turn Manifest List
                          TurnByTurnManifestCard(
                            stops: state.stops,
                            currentStopIndex: state.currentStopIndex,
                          ),

                          const SizedBox(height: UberSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
