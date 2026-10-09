import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class DetourGuaranteeInspector extends StatelessWidget {
  const DetourGuaranteeInspector({
    super.key,
    required this.records,
  });

  final List<ActiveRouteDetourRecord> records;

  double get complianceRate {
    if (records.isEmpty) return 100.0;
    final passCount = records.where((r) => r.isCompliant).length;
    return (passCount / records.length) * 100.0;
  }

  double get maxDetour {
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.detourPercent).fold<double>(0.0, max);
  }

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
                    Icons.verified_user_rounded,
                    size: 18,
                    color: UberColors.accentGreen,
                  ),
                  const SizedBox(width: UberSpacing.xs),
                  Text(
                    'Detour Bounds Guarantee',
                    style: UberTypography.bodyMdStrong,
                  ),
                ],
              ),
              MetricBadge(
                label: '',
                value: '${complianceRate.toStringAsFixed(1)}% Compliant',
                variant: complianceRate == 100.0
                    ? MetricBadgeVariant.success
                    : MetricBadgeVariant.alert,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.sm),

          // Guarantee summary bar
          Container(
            padding: const EdgeInsets.all(UberSpacing.sm),
            decoration: BoxDecoration(
              color: UberColors.accentGreenSoft,
              borderRadius: UberRadii.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ceiling Constraint',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.accentGreen,
                      ),
                    ),
                    Text(
                      '15.0% Ceiling',
                      style: UberTypography.bodySmStrong.copyWith(
                        color: UberColors.accentGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Max Active Detour',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.accentGreen,
                      ),
                    ),
                    Text(
                      '${maxDetour.toStringAsFixed(1)}% Max',
                      style: UberTypography.bodySmStrong.copyWith(
                        color: UberColors.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.sm),

          // Route audit table
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: UberSpacing.xs),
            itemBuilder: (context, index) {
              final r = records[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.sm,
                  vertical: UberSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: UberColors.canvasSoft,
                  borderRadius: UberRadii.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.routeId,
                          style: UberTypography.bodySmStrong,
                        ),
                        Text(
                          'Direct ${r.directDistanceKm.toStringAsFixed(1)} km -> Pooled ${r.pooledDistanceKm.toStringAsFixed(1)} km',
                          style: UberTypography.caption,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${r.detourPercent.toStringAsFixed(1)}%',
                          style: UberTypography.bodySmStrong.copyWith(
                            color: r.isCompliant
                                ? UberColors.accentGreen
                                : UberColors.accentRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        MetricBadge(
                          label: '',
                          value: r.isCompliant ? 'PASS (<= 15%)' : 'VIOLATION',
                          variant: r.isCompliant
                              ? MetricBadgeVariant.success
                              : MetricBadgeVariant.alert,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
