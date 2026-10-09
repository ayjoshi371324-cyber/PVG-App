import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class ComparativeBenchmarkCard extends StatelessWidget {
  const ComparativeBenchmarkCard({
    super.key,
    required this.benchmark,
  });

  final BenchmarkMetrics benchmark;

  @override
  Widget build(BuildContext context) {
    return UberCard(
      variant: UberCardVariant.standard,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.balance_rounded,
                    size: 18,
                    color: UberColors.ink,
                  ),
                  const SizedBox(width: UberSpacing.xs),
                  Text(
                    'Pooling vs. Greedy Baseline',
                    style: UberTypography.bodyMdStrong,
                  ),
                ],
              ),
              MetricBadge(
                label: '',
                value:
                    '${benchmark.vktSavingsPercent.toStringAsFixed(1)}% VKT Saved',
                variant: MetricBadgeVariant.success,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.md),

          // Column Headers
          Row(
            children: [
              const SizedBox(width: 100), // Label spacer
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: UberColors.ink,
                    borderRadius: UberRadii.md,
                  ),
                  child: Center(
                    child: Text(
                      'Algorithmic Pooling',
                      textAlign: TextAlign.center,
                      style: UberTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: UberColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UberSpacing.xs),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: UberColors.canvasSoft,
                    borderRadius: UberRadii.md,
                  ),
                  child: Center(
                    child: Text(
                      'Greedy Baseline',
                      textAlign: TextAlign.center,
                      style: UberTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: UberColors.body,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.sm),

          // Comparison rows
          _buildComparisonRow(
            title: 'Vehicle-km (VKT)',
            leftValue: '${benchmark.vktAlgorithmic.toStringAsFixed(1)} km',
            rightValue: '${benchmark.vktGreedy.toStringAsFixed(1)} km',
            leftPositive: true,
          ),
          const Divider(height: UberSpacing.md),
          _buildComparisonRow(
            title: 'Avg Detour',
            leftValue: '${benchmark.detourAlgorithmic.toStringAsFixed(1)}%',
            rightValue: '${benchmark.detourGreedy.toStringAsFixed(1)}%',
            leftPositive: true,
            leftAnnotation: 'PASS <= 15%',
            rightAnnotation: 'VIOLATION',
          ),
          const Divider(height: UberSpacing.md),
          _buildComparisonRow(
            title: 'Fare Savings',
            leftValue:
                '${benchmark.fareSavingsPercentAlgorithmic.toStringAsFixed(1)}%',
            rightValue:
                '${benchmark.fareSavingsPercentGreedy.toStringAsFixed(1)}%',
            leftPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String title,
    required String leftValue,
    required String rightValue,
    bool leftPositive = true,
    String? leftAnnotation,
    String? rightAnnotation,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: UberTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: UberColors.body,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UberSpacing.xs,
              vertical: UberSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: UberColors.accentGreenSoft,
              borderRadius: UberRadii.md,
            ),
            child: Column(
              children: [
                Text(
                  leftValue,
                  textAlign: TextAlign.center,
                  style: UberTypography.bodySmStrong.copyWith(
                    color: UberColors.accentGreen,
                  ),
                ),
                if (leftAnnotation != null)
                  Text(
                    leftAnnotation,
                    style: UberTypography.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: UberColors.accentGreen,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: UberSpacing.xs),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UberSpacing.xs,
              vertical: UberSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: UberColors.canvasSoft,
              borderRadius: UberRadii.md,
            ),
            child: Column(
              children: [
                Text(
                  rightValue,
                  textAlign: TextAlign.center,
                  style: UberTypography.bodySm.copyWith(
                    color: UberColors.ink,
                  ),
                ),
                if (rightAnnotation != null)
                  Text(
                    rightAnnotation,
                    style: UberTypography.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: UberColors.accentRed,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
