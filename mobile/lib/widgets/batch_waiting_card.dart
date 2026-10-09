import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class BatchWaitingCard extends StatelessWidget {
  const BatchWaitingCard({
    super.key,
    required this.secondsRemaining,
    this.totalSeconds = 15,
    required this.onCancel,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0
        ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular animated countdown gauge
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4.5,
                      backgroundColor: UberColors.canvasSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(UberColors.primary),
                    ),
                    Text(
                      '${secondsRemaining}s',
                      style: UberTypography.bodyMdStrong.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: UberSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Dynamic Batch Intake Active',
                          style: UberTypography.bodyMdStrong.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grouping compatible commuters within a 15-second window to guarantee ≤15% detour & Shapley savings.',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.body,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.md),
          // Micro status badges
          Row(
            children: const [
              MetricBadge(
                label: 'Window',
                value: 'Rolling 15s',
                variant: MetricBadgeVariant.dark,
                compact: true,
              ),
              SizedBox(width: UberSpacing.sm),
              MetricBadge(
                label: 'Detour Ceiling',
                value: '≤ 15.0%',
                variant: MetricBadgeVariant.success,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: UberSpacing.lg),
          // Cancel Request Button
          PillButton(
            key: const Key('cancel_batch_request_button'),
            label: 'Cancel Request',
            variant: PillButtonVariant.outline,
            size: PillButtonSize.medium,
            fullWidth: true,
            icon: Icons.close_rounded,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
