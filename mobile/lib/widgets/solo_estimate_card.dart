import 'package:flutter/material.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class SoloEstimateCard extends StatelessWidget {
  const SoloEstimateCard({
    super.key,
    required this.estimate,
  });

  final SoloRouteEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return UberCard(
      variant: UberCardVariant.tinted,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solo Reference Fare',
                style: UberTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: UberColors.body,
                ),
              ),
              const MetricBadge(
                label: 'Baseline Rate',
                value: '₹20 + ₹10/km',
                variant: MetricBadgeVariant.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                estimate.formattedFare,
                style: UberTypography.displayLg.copyWith(
                  color: UberColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 15.0,
                    color: UberColors.body,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    estimate.formattedDistance,
                    style: UberTypography.bodySmStrong,
                  ),
                  const SizedBox(width: UberSpacing.md),
                  Icon(
                    Icons.access_time_rounded,
                    size: 15.0,
                    color: UberColors.body,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    estimate.formattedDuration,
                    style: UberTypography.bodySmStrong,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
