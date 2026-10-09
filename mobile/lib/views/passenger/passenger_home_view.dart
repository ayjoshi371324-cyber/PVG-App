import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/landmark_chips.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/party_size_selector.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/solo_estimate_card.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class PassengerHomeView extends StatelessWidget {
  const PassengerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Graceful fallback if PassengerCubit is not provided in context
    final cubit = _getPassengerCubit(context);
    if (cubit == null) {
      return BlocProvider(
        create: (_) => PassengerCubit(),
        child: const _PassengerHomeContent(),
      );
    }

    return const _PassengerHomeContent();
  }

  PassengerCubit? _getPassengerCubit(BuildContext context) {
    try {
      return context.read<PassengerCubit>();
    } catch (_) {
      return null;
    }
  }
}

class _PassengerHomeContent extends StatelessWidget {
  const _PassengerHomeContent();

  void _showLocationPicker({
    required BuildContext context,
    required String title,
    required bool isPickup,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return BottomDrawerSheet(
          title: title,
          subtitle: 'Select from key Pune transit hubs & landmarks',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: PuneLandmarks.all.map((loc) {
              return ListTile(
                leading: Icon(
                  isPickup ? Icons.radio_button_checked : Icons.stop_rounded,
                  color: UberColors.ink,
                  size: 20,
                ),
                title: Text(loc.name, style: UberTypography.bodyMdStrong),
                subtitle: loc.landmarkNote != null
                    ? Text(loc.landmarkNote!, style: UberTypography.caption)
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.md,
                  vertical: 2,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: UberRadii.lg,
                ),
                onTap: () {
                  final passengerCubit = context.read<PassengerCubit>();
                  if (isPickup) {
                    passengerCubit.setPickup(loc);
                  } else {
                    passengerCubit.setDropoff(loc);
                  }
                  Navigator.pop(bottomSheetContext);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomDrawer(BuildContext context, PassengerState state) {
    // 1. Batch Waiting Queue active
    if (state.status == PassengerBookingStatus.batchWaiting) {
      return BottomDrawerSheet(
        title: 'Pooling Window Active',
        subtitle: 'Aggregating nearby Pune commuters',
        child: BatchWaitingCard(
          secondsRemaining: state.countdownSeconds,
          totalSeconds: state.totalCountdownSeconds,
          onCancel: () {
            context.read<PassengerCubit>().cancelBatchWaiting();
          },
        ),
      );
    }

    // 2. Offer Received from optimization matching
    if (state.status == PassengerBookingStatus.offerReceived &&
        state.activeOffer != null) {
      return BottomDrawerSheet(
        title: 'Ride Match Found',
        subtitle: 'Guaranteed ≤ 15% detour & Shapley fair savings',
        child: PooledRideOfferCard(
          offer: state.activeOffer!,
          secondsRemaining: state.offerExpirySeconds,
          onAccept: () {
            context.read<PassengerCubit>().acceptOffer();
          },
          onDecline: () {
            context.read<PassengerCubit>().declineOffer();
          },
        ),
      );
    }

    // 3. Active ride accepted (Ready for Ticket 05 live progression)
    if (state.status == PassengerBookingStatus.tripActive) {
      return BottomDrawerSheet(
        title: 'Ride Confirmed & Dispatched',
        subtitle:
            '${state.activeOffer?.vehicleModel ?? "Vehicle"} (${state.activeOffer?.licensePlate ?? "MH-12"})',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UberCard(
              variant: UberCardVariant.tinted,
              padding: const EdgeInsets.all(UberSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: UberColors.accentGreenSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: UberColors.accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UberSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver ${state.activeOffer?.driverName ?? "assigned"} En Route',
                          style: UberTypography.bodyMdStrong,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Arriving in ~${state.activeOffer?.pickupEtaMinutes ?? 4} mins at pickup point',
                          style: UberTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UberSpacing.md),
            PillButton(
              key: const Key('trip_active_cancel_button'),
              label: 'Cancel Active Trip',
              variant: PillButtonVariant.secondary,
              fullWidth: true,
              onPressed: () {
                context.read<PassengerCubit>().declineOffer();
              },
            ),
          ],
        ),
      );
    }

    // 4. Default: Route Planning Sheet
    final estimate = state.estimate;
    return BottomDrawerSheet(
      title: 'Where to in Pune?',
      subtitle: 'Select stops, seats & view baseline solo fare',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Pune Transit Landmark Chips
          LandmarkChips(
            selectedLocation: state.dropoff,
            onLandmarkSelected: (loc) {
              context.read<PassengerCubit>().setDropoff(loc);
            },
          ),
          const SizedBox(height: UberSpacing.md),

          // Location Input Card
          UberCard(
            variant: UberCardVariant.tinted,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              children: [
                // Pickup row
                InkWell(
                  onTap: () => _showLocationPicker(
                    context: context,
                    title: 'Select Pickup Location',
                    isPickup: true,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: UberColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: UberSpacing.md),
                      Expanded(
                        child: Text(
                          state.pickup?.name ?? 'Select pickup point',
                          style: UberTypography.bodyMdStrong,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: UberColors.mute,
                      ),
                    ],
                  ),
                ),

                // Divider with swap button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.5),
                        child: Container(
                          height: 18,
                          width: 1.5,
                          color: UberColors.mute,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          context.read<PassengerCubit>().swapLocations();
                        },
                        borderRadius: UberRadii.pill,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            size: 18,
                            color: UberColors.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Dropoff row
                InkWell(
                  onTap: () => _showLocationPicker(
                    context: context,
                    title: 'Select Drop-off Destination',
                    isPickup: false,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: UberColors.ink,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      const SizedBox(width: UberSpacing.md),
                      Expanded(
                        child: Text(
                          state.dropoff?.name ?? 'Select destination',
                          style: UberTypography.bodyMdStrong,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: UberColors.mute,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.sm),

          // Party Size Selector (1-3 seats)
          PartySizeSelector(
            partySize: state.partySize,
            onIncrement: () {
              context.read<PassengerCubit>().incrementPartySize();
            },
            onDecrement: () {
              context.read<PassengerCubit>().decrementPartySize();
            },
          ),

          if (estimate != null) ...[
            const SizedBox(height: UberSpacing.sm),
            SoloEstimateCard(estimate: estimate),
          ],

          const SizedBox(height: UberSpacing.md),
          PillButton(
            key: const Key('find_shared_pool_button'),
            label: 'Find Shared Pool',
            size: PillButtonSize.large,
            fullWidth: true,
            icon: Icons.directions_car_filled_rounded,
            onPressed: () {
              context.read<PassengerCubit>().startBatchWaiting();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassengerCubit, PassengerState>(
      builder: (context, state) {
        final estimate = state.estimate;

        return Scaffold(
          backgroundColor: UberColors.canvas,
          body: Stack(
            children: [
              // Interactive OpenStreetMap view with route polyline and markers
              Positioned.fill(
                child: PuneMapWidget(
                  pickup: state.pickup,
                  dropoff: state.dropoff,
                  polylinePoints: estimate?.polylinePoints ?? const [],
                ),
              ),

              // Upper floating status badges
              Positioned(
                top: UberSpacing.md,
                left: UberSpacing.lg,
                right: UberSpacing.lg,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: UberSpacing.sm,
                  runSpacing: UberSpacing.xs,
                  children: const [
                    MetricBadge(
                      label: 'Detour Ceiling',
                      value: '≤ 15%',
                      icon: Icons.verified_user_outlined,
                      variant: MetricBadgeVariant.success,
                      compact: true,
                    ),
                    MetricBadge(
                      label: 'Pricing',
                      value: 'Shapley Split',
                      icon: Icons.savings_outlined,
                      variant: MetricBadgeVariant.neutral,
                      compact: true,
                    ),
                  ],
                ),
              ),

              // Bottom Drawer: Dynamically switches based on state
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomDrawer(context, state),
              ),
            ],
          ),
        );
      },
    );
  }
}
