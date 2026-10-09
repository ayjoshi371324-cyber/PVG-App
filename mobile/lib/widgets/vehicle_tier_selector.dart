import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

/// Vehicle Tier Selector widget displaying Auto, Car, and Car XL.
///
/// Disables tiers where `capacity < partySize` with explanatory helper text.
class VehicleTierSelector extends StatelessWidget {
  const VehicleTierSelector({
    super.key,
    required this.selectedTier,
    required this.partySize,
    required this.distanceKm,
    this.baseDurationMinutes = 20,
    required this.onTierSelected,
  });

  final VehicleTier selectedTier;
  final int partySize;
  final double distanceKm;
  final int baseDurationMinutes;
  final ValueChanged<VehicleTier>? onTierSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: UberSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Vehicle Tier',
                style: UberTypography.bodyMdStrong,
              ),
              Text(
                '$partySize ${partySize == 1 ? "passenger" : "passengers"}',
                style: UberTypography.caption.copyWith(color: UberColors.body),
              ),
            ],
          ),
        ),
        Row(
          children: VehicleTier.values.map((tier) {
            final isSelected = tier == selectedTier;
            final canAccommodate = tier.canAccommodatePartySize(partySize);
            final disabledText = tier.disabledReason(partySize);
            final fare = tier.calculateEstimatedFare(distanceKm);
            final etaMinutes = _getEtaMinutes(tier);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: _VehicleTierCard(
                  key: Key('vehicle_tier_${tier.id}'),
                  tier: tier,
                  isSelected: isSelected,
                  isEnabled: canAccommodate,
                  disabledReason: disabledText,
                  estimatedFare: fare,
                  etaMinutes: etaMinutes,
                  onTap: canAccommodate && onTierSelected != null
                      ? () => onTierSelected!(tier)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  int _getEtaMinutes(VehicleTier tier) {
    switch (tier) {
      case VehicleTier.auto:
        return 3;
      case VehicleTier.car:
        return 4;
      case VehicleTier.carXl:
        return 6;
    }
  }
}

class _VehicleTierCard extends StatelessWidget {
  const _VehicleTierCard({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.isEnabled,
    this.disabledReason,
    required this.estimatedFare,
    required this.etaMinutes,
    this.onTap,
  });

  final VehicleTier tier;
  final bool isSelected;
  final bool isEnabled;
  final String? disabledReason;
  final double estimatedFare;
  final int etaMinutes;
  final VoidCallback? onTap;

  IconData _getIcon(VehicleTier tier) {
    switch (tier) {
      case VehicleTier.auto:
        return Icons.electric_rickshaw_rounded;
      case VehicleTier.car:
        return Icons.directions_car_rounded;
      case VehicleTier.carXl:
        return Icons.airport_shuttle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? UberColors.ink : UberColors.mute;
    final backgroundColor = isSelected
        ? UberColors.ink
        : (isEnabled ? UberColors.canvas : UberColors.canvasSoft.withValues(alpha: 0.6));
    final textColor = isSelected ? UberColors.onPrimary : effectiveColor;
    final subtextColor = isSelected
        ? UberColors.mute
        : (isEnabled ? UberColors.body : UberColors.mute);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: UberRadii.lg,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UberSpacing.sm,
              vertical: UberSpacing.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: UberRadii.lg,
              border: Border.all(
                color: isSelected
                    ? UberColors.ink
                    : (isEnabled
                        ? UberColors.mute.withValues(alpha: 0.4)
                        : UberColors.hairlineMid.withValues(alpha: 0.2)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon and ETA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      _getIcon(tier),
                      color: isSelected ? UberColors.onPrimary : effectiveColor,
                      size: 24,
                    ),
                    Text(
                      '${etaMinutes}m',
                      style: UberTypography.caption.copyWith(
                        color: subtextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UberSpacing.sm),

                // Name
                Text(
                  tier.displayName,
                  style: UberTypography.bodyMdStrong.copyWith(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),

                // Capacity badge
                Text(
                  '${tier.capacity} seats',
                  style: UberTypography.caption.copyWith(
                    color: subtextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: UberSpacing.xs),

                // Fare
                Text(
                  '₹${estimatedFare.round()}',
                  style: UberTypography.bodyMdStrong.copyWith(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Disabled helper text if capacity exceeded
                if (!isEnabled && disabledReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    disabledReason!,
                    style: UberTypography.caption.copyWith(
                      color: isSelected ? UberColors.onPrimary : UberColors.accentRed,
                      fontSize: 9.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
