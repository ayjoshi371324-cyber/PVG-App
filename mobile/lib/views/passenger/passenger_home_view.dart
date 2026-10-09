import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/landmark_chips.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
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
                shape: RoundedRectangleBorder(
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

              // Bottom Drawer with Route Selector, Landmarks & Solo Estimate
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomDrawerSheet(
                  title: 'Where to in Pune?',
                  subtitle: 'Select stops & view baseline solo reference fare',
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
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

                      if (estimate != null) ...[
                        const SizedBox(height: UberSpacing.md),
                        SoloEstimateCard(estimate: estimate),
                      ],

                      const SizedBox(height: UberSpacing.md),
                      PillButton(
                        label: 'Request Pooled Ride',
                        size: PillButtonSize.large,
                        fullWidth: true,
                        icon: Icons.directions_car_filled_rounded,
                        onPressed: () {},
                      ),
                    ],
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
