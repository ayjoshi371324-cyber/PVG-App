import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class TurnByTurnManifestCard extends StatelessWidget {
  const TurnByTurnManifestCard({
    super.key,
    required this.stops,
    required this.currentStopIndex,
    this.onStopTap,
  });

  final List<DriverStop> stops;
  final int currentStopIndex;
  final void Function(DriverStop stop)? onStopTap;

  @override
  Widget build(BuildContext context) {
    return UberCard(
      variant: UberCardVariant.standard,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 20,
                    color: UberColors.ink,
                  ),
                  const SizedBox(width: UberSpacing.xs),
                  Text(
                    'Route Stop Manifest',
                    style: UberTypography.bodyMdStrong,
                  ),
                ],
              ),
              MetricBadge(
                label: '',
                value: '${stops.length} Stops',
                variant: MetricBadgeVariant.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stops.length,
            separatorBuilder: (_, _) => const SizedBox(height: UberSpacing.xs),
            itemBuilder: (context, index) {
              final stop = stops[index];
              return _buildStopItem(context, stop, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStopItem(BuildContext context, DriverStop stop, int index) {
    final isCurrent = stop.isCurrent;
    final isCompleted = stop.isCompleted;

    return InkWell(
      onTap: onStopTap != null ? () => onStopTap!(stop) : null,
      borderRadius: UberRadii.lg,
      child: Container(
        padding: const EdgeInsets.all(UberSpacing.sm),
        decoration: BoxDecoration(
          color: isCurrent
              ? UberColors.canvasSofter
              : (isCompleted ? UberColors.canvasSoft.withValues(alpha: 0.5) : Colors.transparent),
          borderRadius: UberRadii.lg,
          border: isCurrent
              ? Border.all(color: UberColors.ink, width: 1.5)
              : Border.all(color: UberColors.canvasSoft, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stop icon & index indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? UberColors.accentGreenSoft
                    : (isCurrent ? UberColors.ink : UberColors.canvasSoft),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : (stop.isPickup
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded),
                  size: 16,
                  color: isCompleted
                      ? UberColors.accentGreen
                      : (isCurrent ? UberColors.onPrimary : UberColors.body),
                ),
              ),
            ),
            const SizedBox(width: UberSpacing.sm),

            // Stop information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${stop.passengerName} (${stop.seats} ${stop.seats == 1 ? 'Seat' : 'Seats'})',
                          style: isCurrent
                              ? UberTypography.bodySmStrong
                              : UberTypography.bodySm.copyWith(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                        ),
                      ),
                      MetricBadge(
                        label: '',
                        value: stop.verificationCode,
                        variant: MetricBadgeVariant.dark,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stop.location.name,
                    style: UberTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? UberColors.mute : UberColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ETA ${stop.etaMinutes} mins • ${stop.distanceKm.toStringAsFixed(1)} km',
                        style: UberTypography.caption.copyWith(
                          color: UberColors.body,
                        ),
                      ),
                      if (isCurrent)
                        const MetricBadge(
                          label: '',
                          value: 'Active Target',
                          variant: MetricBadgeVariant.dark,
                          compact: true,
                        )
                      else if (isCompleted)
                        const MetricBadge(
                          label: '',
                          value: 'Completed',
                          variant: MetricBadgeVariant.success,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
