import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

/// Pill badge certifying that the route detour strictly satisfies the <= 15.0% guarantee.
class DetourGuaranteeBadge extends StatelessWidget {
  const DetourGuaranteeBadge({
    super.key,
    required this.detourPercentage,
    this.compact = false,
  });

  final double detourPercentage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isGuaranteed = detourPercentage <= kMaxDetourGuaranteePercentage;

    final backgroundColor = isGuaranteed
        ? UberColors.accentGreenSoft
        : UberColors.accentRedSoft;
    final borderColor = isGuaranteed
        ? UberColors.accentGreen.withValues(alpha: 0.4)
        : UberColors.accentRed.withValues(alpha: 0.4);
    final textColor = isGuaranteed
        ? UberColors.accentGreen
        : UberColors.accentRed;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? UberSpacing.sm : UberSpacing.md,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: UberRadii.pill,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGuaranteed
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded,
            color: textColor,
            size: compact ? 14 : 16,
          ),
          const SizedBox(width: UberSpacing.xs),
          Text(
            '+${detourPercentage.toStringAsFixed(1)}% Detour',
            style: (compact ? UberTypography.caption : UberTypography.caption)
                .copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: UberSpacing.xs),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: UberSpacing.xs),
          Text(
            '≤ 15% Guaranteed',
            style: (compact ? UberTypography.caption : UberTypography.caption)
                .copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
