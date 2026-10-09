import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/trip_progression_bar.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Bottom drawer sheet content displaying real-time trip execution,
/// driver info, detour guarantee badge, and interactive progression milestones.
class LiveTripTrackingCard extends StatelessWidget {
  const LiveTripTrackingCard({
    super.key,
    required this.trip,
    required this.onAdvanceStep,
    required this.onSimulateJoin,
    required this.onCancel,
  });

  final ActiveTrip trip;
  final VoidCallback onAdvanceStep;
  final VoidCallback onSimulateJoin;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final offer = trip.offer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Driver & Vehicle Card
        UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: UberColors.canvas,
                  borderRadius: UberRadii.md,
                  border: Border.all(color: UberColors.canvasSoft),
                ),
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 26,
                  color: UberColors.ink,
                ),
              ),
              const SizedBox(width: UberSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.vehicleModel,
                      style: UberTypography.bodyMdStrong,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: UberColors.canvas,
                            borderRadius: UberRadii.md,
                            border: Border.all(color: UberColors.canvasSoft),
                          ),
                          child: Text(
                            offer.licensePlate,
                            style: UberTypography.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: UberSpacing.sm),
                        Text(
                          '${offer.driverName} • ★ ${offer.driverRating.toStringAsFixed(1)}',
                          style: UberTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.sm),

        // Live Detour Guarantee & Progress summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DetourGuaranteeBadge(
              detourPercentage: trip.currentDetourPercentage,
              compact: true,
            ),
            Text(
              '${(trip.progress * 100).round()}% Completed',
              style: UberTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: UberColors.ink,
              ),
            ),
          ],
        ),

        const SizedBox(height: UberSpacing.md),

        // Multi-Stop Milestone Progression
        TripProgressionBar(waypoints: trip.waypoints),

        const SizedBox(height: UberSpacing.md),

        // Action controls
        Row(
          children: [
            Expanded(
              flex: 3,
              child: PillButton(
                key: const Key('advance_trip_step_button'),
                label: trip.isCompleted ? 'Complete Ride' : 'Advance Stop',
                variant: PillButtonVariant.primary,
                size: PillButtonSize.large,
                icon: Icons.navigation_rounded,
                fullWidth: true,
                onPressed: onAdvanceStep,
              ),
            ),
            const SizedBox(width: UberSpacing.sm),
            Expanded(
              flex: 2,
              child: PillButton(
                key: const Key('simulate_mid_trip_join_button'),
                label: '+ Joiner',
                variant: PillButtonVariant.secondary,
                size: PillButtonSize.large,
                icon: Icons.person_add_alt_1_rounded,
                fullWidth: true,
                onPressed: onSimulateJoin,
              ),
            ),
          ],
        ),

        const SizedBox(height: UberSpacing.xs),
        Center(
          child: TextButton(
            key: const Key('cancel_active_trip_button'),
            onPressed: onCancel,
            child: Text(
              'Cancel Ride',
              style: UberTypography.caption.copyWith(
                color: UberColors.mute,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
