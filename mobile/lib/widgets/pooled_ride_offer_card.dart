import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/shapley_fare_breakdown_card.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Elevated card presenting the matched pooled ride offer, vehicle details,
/// detour guarantee certification, Shapley fair-fare breakdown, and accept/decline actions.
class PooledRideOfferCard extends StatelessWidget {
  const PooledRideOfferCard({
    super.key,
    required this.offer,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onDecline,
  });

  final PooledRideOffer offer;
  final int secondsRemaining;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top status row: Matched status + Live Expiry Countdown Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: UberColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: UberSpacing.xs),
                Text(
                  'MATCHED POOL OFFER',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: UberColors.ink,
                  ),
                ),
              ],
            ),
            // Expiry countdown badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UberSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: secondsRemaining <= 5
                    ? UberColors.accentRedSoft
                    : UberColors.canvasSoft,
                borderRadius: UberRadii.pill,
                border: Border.all(
                  color: secondsRemaining <= 5
                      ? UberColors.accentRed
                      : UberColors.canvasSoft,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: secondsRemaining <= 5
                        ? UberColors.accentRed
                        : UberColors.body,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in ${secondsRemaining}s',
                    style: UberTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: secondsRemaining <= 5
                          ? UberColors.accentRed
                          : UberColors.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: UberSpacing.sm),

        // Vehicle, Driver, & Capacity Card
        UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Icon Box
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
                  // Vehicle Model & Plate
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

              const SizedBox(height: UberSpacing.sm),
              const Divider(height: 1, color: UberColors.canvasSoft),
              const SizedBox(height: UberSpacing.sm),

              // Route ETAs and Co-passengers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Pickup ETA', '${offer.pickupEtaMinutes} min'),
                  _buildMetric('Drop-off ETA', '${offer.dropoffEtaMinutes} min'),
                  _buildMetric(
                    'Co-Riders',
                    '${offer.coPassengersCount} matched',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.sm),

        // Prominent Detour Guarantee Badge & Co-passenger banner
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: UberSpacing.sm,
          runSpacing: UberSpacing.xs,
          children: [
            DetourGuaranteeBadge(
              detourPercentage: offer.detourPercentage,
            ),
            Text(
              '${offer.coPassengersCount} Co-passengers sharing route',
              style: UberTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: UberColors.body,
              ),
            ),
          ],
        ),

        const SizedBox(height: UberSpacing.sm),

        // Shapley Fair-Fare Breakdown Card
        ShapleyFareBreakdownCard(
          breakdown: offer.fareBreakdown,
        ),

        const SizedBox(height: UberSpacing.md),

        // Action Buttons: Accept & Decline
        Row(
          children: [
            Expanded(
              flex: 2,
              child: PillButton(
                key: const Key('decline_pool_offer_button'),
                label: 'Decline',
                variant: PillButtonVariant.secondary,
                size: PillButtonSize.large,
                fullWidth: true,
                onPressed: onDecline,
              ),
            ),
            const SizedBox(width: UberSpacing.sm),
            Expanded(
              flex: 5,
              child: PillButton(
                key: const Key('accept_pool_offer_button'),
                label: 'Accept Pooled Ride',
                variant: PillButtonVariant.primary,
                size: PillButtonSize.large,
                icon: Icons.check_circle_rounded,
                fullWidth: true,
                onPressed: onAccept,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: UberTypography.caption.copyWith(color: UberColors.mute),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: UberTypography.bodySmStrong,
        ),
      ],
    );
  }
}
