import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';

/// Segmented horizontal bar displaying cabin occupancy breakdown:
/// - Onboard (occupied)
/// - Reserved (confirmed / waiting pickup)
/// - Held (offered / pending consent)
/// - Free (available)
class CabinOccupancyBar extends StatelessWidget {
  const CabinOccupancyBar({
    super.key,
    required this.maxCapacity,
    required this.onboardSeats,
    this.reservedSeats = 0,
    this.heldSeats = 0,
    this.showLabels = true,
    this.height = 8.0,
  });

  final int maxCapacity;
  final int onboardSeats;
  final int reservedSeats;
  final int heldSeats;
  final bool showLabels;
  final double height;

  int get freeSeats => (maxCapacity - onboardSeats - reservedSeats - heldSeats).clamp(0, maxCapacity);

  @override
  Widget build(BuildContext context) {
    final cap = maxCapacity > 0 ? maxCapacity : 1;
    final onboardFlex = onboardSeats.clamp(0, cap);
    final reservedFlex = reservedSeats.clamp(0, cap);
    final heldFlex = heldSeats.clamp(0, cap);
    final freeFlex = freeSeats.clamp(0, cap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Segmented Bar
        Container(
          key: const Key('cabin_occupancy_bar_container'),
          height: height,
          decoration: BoxDecoration(
            color: UberColors.canvasSoft,
            borderRadius: UberRadii.pill,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              if (onboardFlex > 0)
                Expanded(
                  flex: onboardFlex,
                  child: Container(
                    color: UberColors.ink,
                  ),
                ),
              if (reservedFlex > 0)
                Expanded(
                  flex: reservedFlex,
                  child: Container(
                    color: const Color(0xFF2563EB), // Accent Blue
                  ),
                ),
              if (heldFlex > 0)
                Expanded(
                  flex: heldFlex,
                  child: Container(
                    color: UberColors.accentOrange, // Accent Orange
                  ),
                ),
              if (freeFlex > 0)
                Expanded(
                  flex: freeFlex,
                  child: Container(
                    color: UberColors.surfacePressed, // Neutral Soft
                  ),
                ),
            ],
          ),
        ),

        if (showLabels) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: UberSpacing.sm,
            runSpacing: 4,
            children: [
              _buildLegendDot(
                color: UberColors.ink,
                label: 'Onboard: $onboardSeats',
              ),
              _buildLegendDot(
                color: const Color(0xFF2563EB),
                label: 'Reserved: $reservedSeats',
              ),
              _buildLegendDot(
                color: UberColors.accentOrange,
                label: 'Held: $heldSeats',
              ),
              _buildLegendDot(
                color: UberColors.body,
                label: 'Free: $freeSeats',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: UberTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: UberColors.ink,
          ),
        ),
      ],
    );
  }
}
