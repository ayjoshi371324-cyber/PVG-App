import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Modal bottom sheet presenting a dynamic mid-trip passenger join request
/// and requesting two-way consent with verified <= 15% detour guarantee.
class MidTripConsentSheet extends StatelessWidget {
  const MidTripConsentSheet({
    super.key,
    required this.joinRequest,
    required this.onApprove,
    required this.onReject,
  });

  final MidTripJoinRequest joinRequest;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return BottomDrawerSheet(
      title: 'Mid-Trip Join Request',
      subtitle: 'A compatible Pune commuter wants to join your route',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rider Info Card
          UberCard(
            variant: UberCardVariant.tinted,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: UberColors.canvas,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: UberColors.ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: UberSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        joinRequest.passengerName,
                        style: UberTypography.bodyMdStrong,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pickup: ${joinRequest.pickupLocation.name}\nDrop-off: ${joinRequest.dropoffLocation.name}',
                        style: UberTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Detour Re-Verification & Guarantee Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DetourGuaranteeBadge(
                detourPercentage: joinRequest.newDetourPercentage,
              ),
              Text(
                'Delta: +${joinRequest.detourDelta.toStringAsFixed(1)}%',
                style: UberTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: UberColors.body,
                ),
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.sm),

          // Savings Benefit Card
          Container(
            padding: const EdgeInsets.all(UberSpacing.md),
            decoration: BoxDecoration(
              color: UberColors.accentGreenSoft,
              borderRadius: UberRadii.md,
              border: Border.all(
                color: UberColors.accentGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: UberColors.accentGreen,
                  size: 20,
                ),
                const SizedBox(width: UberSpacing.sm),
                Expanded(
                  child: Text(
                    'Your fare drops by an additional ₹${joinRequest.additionalSavings.round()} (New fare: ₹${joinRequest.newSharedFare.round()})',
                    style: UberTypography.bodySmStrong.copyWith(
                      color: UberColors.accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.lg),

          // Two-Way Consent Action Buttons
          PillButton(
            key: const Key('approve_mid_trip_join_button'),
            label: 'Approve Route Adjustment',
            variant: PillButtonVariant.primary,
            size: PillButtonSize.large,
            icon: Icons.check_rounded,
            fullWidth: true,
            onPressed: onApprove,
          ),
          const SizedBox(height: UberSpacing.sm),
          PillButton(
            key: const Key('reject_mid_trip_join_button'),
            label: 'Keep Current Route',
            variant: PillButtonVariant.secondary,
            size: PillButtonSize.large,
            fullWidth: true,
            onPressed: onReject,
          ),
        ],
      ),
    );
  }
}
