import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/widgets/batch_outcome_card.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/landmark_chips.dart';
import 'package:ridepool_app/widgets/live_trip_tracking_card.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/mid_trip_consent_sheet.dart';
import 'package:ridepool_app/widgets/party_size_selector.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/place_search_field.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';
import 'package:ridepool_app/widgets/solo_estimate_card.dart';
import 'package:ridepool_app/widgets/trip_history_sheet.dart';
import 'package:ridepool_app/widgets/trip_receipt_card.dart';
import 'package:ridepool_app/widgets/uber_card.dart';
import 'package:ridepool_app/widgets/vehicle_tier_selector.dart';

class PassengerHomeView extends StatelessWidget {
  const PassengerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
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

  Widget _buildBottomDrawer(BuildContext context, PassengerState state) {
    // 0. Viewing Past Trip History
    if (state.isViewingHistory) {
      return TripHistorySheet(
        history: state.tripHistory,
        onClose: () {
          context.read<PassengerCubit>().toggleTripHistory(false);
        },
      );
    }

    // 1. Trip Completed Receipt Screen
    if (state.status == PassengerBookingStatus.tripCompleted &&
        state.activeReceipt != null) {
      return BottomDrawerSheet(
        title: 'Trip Completed',
        subtitle: 'Arrived safely at destination',
        child: TripReceiptCard(
          receipt: state.activeReceipt!,
          onPaymentSuccess: (updated) {
            context.read<PassengerCubit>().settleReceiptPayment(updated);
          },
          onDone: () {
            context.read<PassengerCubit>().dismissReceipt();
          },
        ),
      );
    }

    // 2. Batch Waiting Queue active
    if (state.status == PassengerBookingStatus.batchWaiting) {
      return BottomDrawerSheet(
        title: 'Pooling Window Active',
        subtitle: 'Aggregating nearby Pune commuters in ${state.selectedTier.displayName} tier',
        child: BatchWaitingCard(
          secondsRemaining: state.countdownSeconds,
          totalSeconds: state.totalCountdownSeconds,
          onCancel: () {
            context.read<PassengerCubit>().cancelBatchWaiting();
          },
        ),
      );
    }

    // 3. Batch Outcome (No Valid Match / Solo Direct Ride)
    if (state.status == PassengerBookingStatus.batchOutcome &&
        state.matchingOutcome != null) {
      final outcome = state.matchingOutcome!;
      return BottomDrawerSheet(
        title: outcome is SoloDirectRideOutcome
            ? 'Solo Ride Dispatched'
            : 'Batch Matching Outcome',
        subtitle: outcome is SoloDirectRideOutcome
            ? 'Zero detour direct dispatch'
            : 'Deterministic combinatorial matching result',
        child: BatchOutcomeCard(
          outcome: outcome,
          onAcceptSolo: () {
            if (outcome is SoloDirectRideOutcome) {
              context
                  .read<PassengerCubit>()
                  .acceptSoloDirectRide(outcome);
            } else {
              // Create solo dispatch for current route & tier
              final cubit = context.read<PassengerCubit>();
              final soloDist = state.estimate?.distanceKm ?? 10.0;
              final soloFare = state.selectedTier.calculateEstimatedFare(soloDist);
              final soloOutcome = SoloDirectRideOutcome(
                vehicle: BatchVehicle(
                  id: 'v-solo-direct',
                  model: 'Direct ${state.selectedTier.displayName} Cab',
                  licensePlate: 'MH-12-RP-9999',
                  driverName: 'Ramesh N.',
                  driverRating: 4.9,
                  tier: state.selectedTier,
                  currentLocation: state.pickup ?? PuneLandmarks.kothrud,
                ),
                request: BatchRideRequest(
                  id: 'req-solo-${DateTime.now().millisecondsSinceEpoch}',
                  passengerName: 'You',
                  pickup: state.pickup ?? PuneLandmarks.kothrud,
                  dropoff: state.dropoff ?? PuneLandmarks.hinjawadiPhase1,
                  partySize: state.partySize,
                  tier: state.selectedTier,
                ),
                distanceKm: soloDist,
                soloFare: soloFare,
                explanation: 'Direct solo ride dispatched with no pooling detour.',
              );
              cubit.acceptSoloDirectRide(soloOutcome);
            }
          },
          onRetryBatch: () {
            context.read<PassengerCubit>().startBatchWaiting();
          },
          onDismiss: () {
            context.read<PassengerCubit>().dismissBatchOutcome();
          },
        ),
      );
    }

    // 4. Offer Received from optimization matching
    if (state.status == PassengerBookingStatus.offerReceived &&
        state.activeOffer != null) {
      return BottomDrawerSheet(
        title: 'Ride Match Found',
        subtitle:
            'Guaranteed ≤ 15% detour & Shapley fair savings (${state.selectedTier.displayName})',
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

    // 5. Active ride tracking & mid-trip join consent
    if (state.status == PassengerBookingStatus.tripActive &&
        state.activeTrip != null) {
      final trip = state.activeTrip!;

      if (trip.pendingJoinRequest != null) {
        return MidTripConsentSheet(
          joinRequest: trip.pendingJoinRequest!,
          onApprove: () {
            context.read<PassengerCubit>().approveMidTripJoin();
          },
          onReject: () {
            context.read<PassengerCubit>().rejectMidTripJoin();
          },
        );
      }

      return BottomDrawerSheet(
        title: 'Trip in Progress',
        subtitle:
            '${trip.offer.vehicleModel} (${trip.offer.licensePlate}) • Pune Corridor',
        child: LiveTripTrackingCard(
          trip: trip,
          onAdvanceStep: () {
            context.read<PassengerCubit>().advanceTripStep();
          },
          onSimulateJoin: () {
            context.read<PassengerCubit>().requestMidTripJoin(
                  MidTripJoinRequest(
                    requestId:
                        'join-sim-${DateTime.now().millisecondsSinceEpoch}',
                    passengerName: 'Vikram S.',
                    pickupLocation: const PuneLocation(
                      name: 'Bavdhan Flyover',
                      latitude: 18.5126,
                      longitude: 73.7712,
                    ),
                    dropoffLocation: PuneLandmarks.hinjawadiPhase1,
                    previousDetourPercentage: trip.currentDetourPercentage,
                    newDetourPercentage: 11.5,
                    additionalSavings: 25.0,
                    newSharedFare: 171.0,
                    etaDeltaMinutes: 3,
                    updatedEtaMinutes: 27,
                    secondsRemaining: 30,
                  ),
                );
          },
          onCancel: () {
            context.read<PassengerCubit>().cancelActiveTripPreDeparture();
          },
        ),
      );
    }

    // 6. Default: Route Planning Sheet
    final estimate = state.estimate;
    final cubit = context.read<PassengerCubit>();

    return BottomDrawerSheet(
      title: 'Where to in Pune?',
      subtitle: 'Typed search, vehicle tiers & dynamic batch intake',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Pune Transit Landmark Chips
          LandmarkChips(
            selectedLocation: state.dropoff,
            onLandmarkSelected: (loc) {
              cubit.setDropoff(loc);
            },
          ),
          const SizedBox(height: UberSpacing.md),

          // Typed Location Search Card with coordinate validation
          UberCard(
            variant: UberCardVariant.tinted,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              children: [
                // Pickup Search Field
                PlaceSearchField(
                  label: 'Pickup',
                  selectedLocation: state.pickup,
                  isPickup: true,
                  onLocationSelected: (loc) {
                    cubit.setPickup(loc);
                  },
                  onChooseOnMapTap: () {
                    cubit.startPinConfirmationMode(isPickup: true);
                  },
                ),

                // Divider with location swap button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.5),
                        child: Container(
                          height: 16,
                          width: 1.5,
                          color: UberColors.mute,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          cubit.swapLocations();
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

                // Dropoff Search Field
                PlaceSearchField(
                  label: 'Drop-off',
                  selectedLocation: state.dropoff,
                  isPickup: false,
                  onLocationSelected: (loc) {
                    cubit.setDropoff(loc);
                  },
                  onChooseOnMapTap: () {
                    cubit.startPinConfirmationMode(isPickup: false);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Vehicle Tier Selector: Auto (3 seats, 0.8x), Car (4 seats, 1.0x), Car XL (6 seats, 1.4x)
          VehicleTierSelector(
            selectedTier: state.selectedTier,
            partySize: state.partySize,
            distanceKm: estimate?.distanceKm ?? 10.0,
            baseDurationMinutes: estimate?.durationMinutes ?? 20,
            onTierSelected: (tier) {
              cubit.setVehicleTier(tier);
            },
          ),

          const SizedBox(height: UberSpacing.md),

          // Party Size Selector (1-6 seats)
          PartySizeSelector(
            partySize: state.partySize,
            maxCapacity: 6,
            onIncrement: () {
              cubit.incrementPartySize(allowTierUpgrade: true);
            },
            onDecrement: () {
              cubit.decrementPartySize();
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
              cubit.startBatchWaiting();
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
        final activeTrip = state.activeTrip;
        final cubit = context.read<PassengerCubit>();

        List<LatLng> confirmedPoints = estimate?.polylinePoints ?? const [];
        List<LatLng> completedPoints = const [];
        List<LatLng> proposedPoints = const [];

        if (activeTrip != null) {
          if (activeTrip.currentWaypointIndex > 0 && confirmedPoints.isNotEmpty) {
            final splitIdx = ((activeTrip.progress * confirmedPoints.length).round())
                .clamp(0, confirmedPoints.length);
            completedPoints = confirmedPoints.sublist(0, splitIdx);
            confirmedPoints = confirmedPoints.sublist(splitIdx);
          }
          if (activeTrip.pendingJoinRequest != null) {
            final joinReq = activeTrip.pendingJoinRequest!;
            proposedPoints = [
              activeTrip.vehiclePosition,
              joinReq.pickupLocation.toLatLng(),
              joinReq.dropoffLocation.toLatLng(),
            ];
          }
        }

        return Scaffold(
          backgroundColor: UberColors.canvas,
          body: Stack(
            children: [
              // Interactive OpenStreetMap view with multi-passenger stops, markers, and polylines
              Positioned.fill(
                child: PuneMapWidget(
                  pickup: state.pickup,
                  dropoff: state.dropoff,
                  waypoints: activeTrip?.waypoints ?? const [],
                  confirmedPolylinePoints: confirmedPoints,
                  completedPolylinePoints: completedPoints,
                  proposedPolylinePoints: proposedPoints,
                  vehiclePosition: activeTrip?.vehiclePosition,
                  onMapTap: state.isPinConfirmationMode
                      ? (point) {
                          final loc = PuneLocation(
                            name:
                                '${state.pinTargetIsPickup ? "Pickup" : "Drop-off"} Pin (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})',
                            latitude: point.latitude,
                            longitude: point.longitude,
                            landmarkNote: 'Confirmed via map pin tap',
                          );
                          cubit.setPendingPinLocation(loc);
                        }
                      : null,
                ),
              ),

              // Bottom Drawer: Dynamically switches based on state
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomDrawer(context, state),
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
                  children: [
                    MetricBadge(
                      label: activeTrip != null ? 'Active Detour' : 'Detour Ceiling',
                      value: activeTrip != null
                          ? '+${activeTrip.currentDetourPercentage.toStringAsFixed(1)}%'
                          : '≤ 15%',
                      icon: Icons.verified_user_outlined,
                      variant: MetricBadgeVariant.success,
                      compact: true,
                    ),
                    InkWell(
                      key: const Key('view_history_button'),
                      borderRadius: UberRadii.pill,
                      onTap: () {
                        cubit.toggleTripHistory(!state.isViewingHistory);
                      },
                      child: MetricBadge(
                        label: 'History',
                        value: state.tripHistory.isEmpty
                            ? 'Past Rides'
                            : '${state.tripHistory.length} Past',
                        icon: Icons.history_rounded,
                        variant: state.isViewingHistory
                            ? MetricBadgeVariant.dark
                            : MetricBadgeVariant.neutral,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Map Pin Confirmation Mode Banner
              if (state.isPinConfirmationMode)
                Positioned(
                  top: UberSpacing.xxxl + 20,
                  left: UberSpacing.lg,
                  right: UberSpacing.lg,
                  child: UberCard(
                    variant: UberCardVariant.elevated,
                    padding: const EdgeInsets.all(UberSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.pin_drop_rounded,
                              color: UberColors.accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: UberSpacing.sm),
                            Expanded(
                              child: Text(
                                'Tap Map to Position ${state.pinTargetIsPickup ? "Pickup" : "Drop-off"}',
                                style: UberTypography.bodyMdStrong,
                              ),
                            ),
                          ],
                        ),
                        if (state.pendingPinLocation != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              state.pendingPinLocation!.name,
                              style: UberTypography.caption.copyWith(
                                color: UberColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: UberSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              key: const Key('cancel_map_pin_button'),
                              onPressed: () {
                                cubit.cancelPinConfirmationMode();
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: UberSpacing.sm),
                            PillButton(
                              key: const Key('confirm_map_pin_button'),
                              label: 'Confirm Pin',
                              variant: PillButtonVariant.primary,
                              size: PillButtonSize.small,
                              onPressed: state.pendingPinLocation != null
                                  ? () {
                                      cubit.confirmMapPin(
                                          state.pendingPinLocation!);
                                    }
                                  : null,
                            ),
                          ],
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
