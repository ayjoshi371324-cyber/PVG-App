import 'package:flutter/material.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Card displayed when batch matching finishes with a truthful non-pooled state:
/// - [NoValidMatchOutcome] with explicit reason (>15% detour, capacity, or time window)
/// - [SoloDirectRideOutcome] with direct solo dispatched option
class BatchOutcomeCard extends StatelessWidget {
  const BatchOutcomeCard({
    super.key,
    required this.outcome,
    required this.onAcceptSolo,
    required this.onRetryBatch,
    required this.onDismiss,
  });

  final BatchMatchingOutcome outcome;
  final VoidCallback onAcceptSolo;
  final VoidCallback onRetryBatch;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (outcome is SoloDirectRideOutcome) {
      final solo = outcome as SoloDirectRideOutcome;
      return _buildSoloCard(context, solo);
    }

    if (outcome is NoValidMatchOutcome) {
      final noMatch = outcome as NoValidMatchOutcome;
      return _buildNoMatchCard(context, noMatch);
    }

    return const SizedBox.shrink();
  }

  Widget _buildNoMatchCard(BuildContext context, NoValidMatchOutcome noMatch) {
    String reasonBadgeText;
    MetricBadgeVariant badgeVariant;

    switch (noMatch.reason) {
      case NoMatchReason.detourExceeded:
        reasonBadgeText = '>15% Detour Guarantee';
        badgeVariant = MetricBadgeVariant.warning;
        break;
      case NoMatchReason.capacityExceeded:
        reasonBadgeText = 'Capacity Limit';
        badgeVariant = MetricBadgeVariant.warning;
        break;
      case NoMatchReason.timeWindowExceeded:
        reasonBadgeText = 'Window Elapsed';
        badgeVariant = MetricBadgeVariant.neutral;
        break;
      case NoMatchReason.tierMismatch:
        reasonBadgeText = 'Tier Unavailable';
        badgeVariant = MetricBadgeVariant.warning;
        break;
    }

    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: UberColors.accentOrangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: UberColors.accentOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: UberSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Valid Shared Match',
                      style: UberTypography.bodyMdStrong.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Deterministic matching verified all constraints',
                      style: UberTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.md),

          // Reason badge
          Wrap(
            spacing: UberSpacing.sm,
            runSpacing: UberSpacing.xs,
            children: [
              MetricBadge(
                label: 'Rejection Reason',
                value: reasonBadgeText,
                variant: badgeVariant,
                compact: true,
              ),
              if (noMatch.observedDetour != null)
                MetricBadge(
                  label: 'Observed Detour',
                  value: '${noMatch.observedDetour!.toStringAsFixed(1)}%',
                  variant: MetricBadgeVariant.warning,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: UberSpacing.sm),

          // Truthful explanation
          Container(
            padding: const EdgeInsets.all(UberSpacing.md),
            decoration: BoxDecoration(
              color: UberColors.canvasSoft,
              borderRadius: UberRadii.md,
            ),
            child: Text(
              noMatch.explanation,
              style: UberTypography.bodyMd.copyWith(
                fontSize: 13,
                color: UberColors.body,
              ),
            ),
          ),
          const SizedBox(height: UberSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: PillButton(
                  key: const Key('try_again_batch_button'),
                  label: 'Try Next Batch',
                  variant: PillButtonVariant.outline,
                  size: PillButtonSize.medium,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetryBatch,
                ),
              ),
              const SizedBox(width: UberSpacing.sm),
              Expanded(
                child: PillButton(
                  key: const Key('book_solo_direct_button'),
                  label: 'Solo Direct Ride',
                  variant: PillButtonVariant.primary,
                  size: PillButtonSize.medium,
                  icon: Icons.directions_car_rounded,
                  onPressed: onAcceptSolo,
                ),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.xs),
          TextButton(
            key: const Key('dismiss_batch_outcome_button'),
            onPressed: onDismiss,
            child: Text(
              'Back to Route Planning',
              style: UberTypography.caption.copyWith(
                color: UberColors.body,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoloCard(BuildContext context, SoloDirectRideOutcome solo) {
    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: UberColors.canvasSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: UberColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(width: UberSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solo Direct Ride',
                      style: UberTypography.bodyMdStrong.copyWith(fontSize: 16),
                    ),
                    Text(
                      '${solo.vehicle.tier.displayName} • ${solo.vehicle.model}',
                      style: UberTypography.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${solo.soloFare.round()}',
                style: UberTypography.bodyMdStrong.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.md),

          Wrap(
            spacing: UberSpacing.sm,
            runSpacing: UberSpacing.xs,
            children: [
              const MetricBadge(
                label: 'Detour',
                value: '0.0% (Direct)',
                variant: MetricBadgeVariant.success,
                compact: true,
              ),
              MetricBadge(
                label: 'Distance',
                value: '${solo.distanceKm.toStringAsFixed(1)} km',
                variant: MetricBadgeVariant.dark,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.sm),

          Text(
            solo.explanation,
            style: UberTypography.caption.copyWith(color: UberColors.body),
          ),
          const SizedBox(height: UberSpacing.lg),

          PillButton(
            key: const Key('confirm_solo_ride_button'),
            label: 'Confirm Solo Ride (₹${solo.soloFare.round()})',
            variant: PillButtonVariant.primary,
            size: PillButtonSize.large,
            fullWidth: true,
            icon: Icons.check_circle_outline_rounded,
            onPressed: onAcceptSolo,
          ),
          const SizedBox(height: UberSpacing.xs),
          TextButton(
            key: const Key('dismiss_batch_outcome_button'),
            onPressed: onDismiss,
            child: Text(
              'Back to Route Planning',
              style: UberTypography.caption.copyWith(
                color: UberColors.body,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
