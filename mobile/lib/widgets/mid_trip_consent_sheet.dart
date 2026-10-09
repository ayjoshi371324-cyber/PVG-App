import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Modal bottom sheet presenting a dynamic mid-trip passenger join request
/// and requesting two-way consent with explicit ETA, detour, and fare deltas
/// alongside a 30s countdown timer.
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
          // 30s Multi-party Countdown Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Multi-Party Consent Protocol',
                style: UberTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: UberColors.body,
                ),
              ),
              Container(
                key: const Key('consent_countdown_indicator'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: joinRequest.secondsRemaining <= 10
                      ? UberColors.accentRedSoft
                      : UberColors.canvasSoft,
                  borderRadius: UberRadii.pill,
                  border: Border.all(
                    color: joinRequest.secondsRemaining <= 10
                        ? UberColors.accentRed
                        : UberColors.hairlineMid.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: joinRequest.secondsRemaining <= 10
                          ? UberColors.accentRed
                          : UberColors.ink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${joinRequest.secondsRemaining}s remaining',
                      style: UberTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: joinRequest.secondsRemaining <= 10
                            ? UberColors.accentRed
                            : UberColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.sm),

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

          // Explicit Delta Metric Trio: ETA Delta | Detour Delta | Fare Delta
          UberCard(
            variant: UberCardVariant.standard,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EXPLICIT ROUTE & FARE DELTAS',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 10,
                    color: UberColors.mute,
                  ),
                ),
                const SizedBox(height: UberSpacing.sm),
                Row(
                  children: [
                    // ETA Delta Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ETA Delta',
                            style: UberTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${joinRequest.etaDeltaMinutes} mins',
                            style: UberTypography.bodySmStrong.copyWith(
                              color: UberColors.ink,
                            ),
                          ),
                          Text(
                            'New: ${joinRequest.updatedEtaMinutes} min',
                            style: UberTypography.caption.copyWith(
                              fontSize: 10,
                              color: UberColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: UberColors.canvasSoft,
                    ),
                    const SizedBox(width: UberSpacing.sm),
                    // Detour Delta Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detour Delta',
                            style: UberTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${joinRequest.detourDelta.toStringAsFixed(1)}%',
                            style: UberTypography.bodySmStrong.copyWith(
                              color: UberColors.ink,
                            ),
                          ),
                          Text(
                            'Total: +${joinRequest.newDetourPercentage.toStringAsFixed(1)}%',
                            style: UberTypography.caption.copyWith(
                              fontSize: 10,
                              color: UberColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: UberColors.canvasSoft,
                    ),
                    const SizedBox(width: UberSpacing.sm),
                    // Fare Delta Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fare Delta',
                            style: UberTypography.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${joinRequest.newSharedFare.round()}',
                            style: UberTypography.bodySmStrong.copyWith(
                              color: UberColors.accentGreen,
                            ),
                          ),
                          Text(
                            'Discounted',
                            style: UberTypography.caption.copyWith(
                              fontSize: 10,
                              color: UberColors.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.sm),

          // Detour Guarantee Badge
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
