import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/uber_card.dart';
import 'package:ridepool_app/widgets/why_am_i_paying_sheet.dart';

/// Card presenting the transparent Shapley-value fair fare calculation
/// comparing baseline solo price vs. the discounted pooled fare.
class ShapleyFareBreakdownCard extends StatelessWidget {
  const ShapleyFareBreakdownCard({
    super.key,
    required this.breakdown,
  });

  final ShapleyFareBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final soloRounded = breakdown.soloFare.round();
    final sharedRounded = breakdown.sharedFare.round();
    final savingsRounded = breakdown.savings.round();
    final savingsPercentRounded = breakdown.savingsPercentage.round();

    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Shapley balance icon badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: UberColors.canvasSoft,
                  borderRadius: UberRadii.md,
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  size: 16,
                  color: UberColors.ink,
                ),
              ),
              const SizedBox(width: UberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shapley Fair-Fare Allocation',
                      style: UberTypography.bodyMdStrong,
                    ),
                    Text(
                      'Cooperative coalition pricing (${breakdown.coalitionSize} riders)',
                      style: UberTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.md),

          // Main Price & Savings Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹$sharedRounded',
                style: UberTypography.displaySm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: UberColors.ink,
                ),
              ),
              const SizedBox(width: UberSpacing.sm),
              Text(
                '₹$soloRounded',
                style: UberTypography.bodyMd.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: UberColors.mute,
                ),
              ),
              const Spacer(),
              // Savings Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: UberColors.accentGreenSoft,
                  borderRadius: UberRadii.pill,
                  border: Border.all(
                    color: UberColors.accentGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Save ₹$savingsRounded ($savingsPercentRounded% off)',
                  style: UberTypography.caption.copyWith(
                    color: UberColors.accentGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.md),
          const Divider(height: 1, color: UberColors.canvasSoft),
          const SizedBox(height: UberSpacing.sm),

          // Detailed breakdown rows
          _buildRow('Solo Baseline Fare', '₹$soloRounded'),
          _buildRow(
            'Coalition Discount (${breakdown.coalitionSize} riders)',
            '-₹$savingsRounded',
            isDiscount: true,
          ),
          if (breakdown.partySize > 1)
            _buildRow(
              'Party of ${breakdown.partySize}',
              '₹${breakdown.perPersonFare.round()} / person',
              isHighlight: true,
            ),
          _buildRow(
            'Your Final Pooled Fare',
            '₹$sharedRounded',
            isBold: true,
          ),

          if (breakdown.passengerShares.isNotEmpty) ...[
            const SizedBox(height: UberSpacing.xs),
            const Divider(height: 1, color: UberColors.canvasSoft),
            const SizedBox(height: UberSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Co-Passenger Shares (Exact Sum)',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: UberColors.body,
                  ),
                ),
                Text(
                  'Total: ₹${breakdown.totalTripCost.round()}',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: UberColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            ...breakdown.passengerShares.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: UberTypography.caption.copyWith(
                          color: e.key.contains('(You)')
                              ? UberColors.accentGreen
                              : UberColors.body,
                          fontWeight: e.key.contains('(You)')
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${e.value.toStringAsFixed(2)}',
                        style: UberTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: UberColors.ink,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          const SizedBox(height: UberSpacing.xs),
          Text(
            breakdown.explanation,
            style: UberTypography.caption.copyWith(
              color: UberColors.body,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: UberSpacing.sm),

          // Interactive "Why am I paying this fare?" Expandable Sheet Button
          InkWell(
            key: const Key('why_am_i_paying_this_fare_button'),
            borderRadius: UberRadii.md,
            onTap: () {
              WhyAmIPayingSheet.show(context, breakdown);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UberSpacing.sm,
                vertical: UberSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: UberColors.canvasSoft,
                borderRadius: UberRadii.md,
                border: Border.all(color: UberColors.surfacePressed),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: UberColors.ink,
                      ),
                      const SizedBox(width: UberSpacing.xs),
                      Text(
                        'Why am I paying this fare?',
                        style: UberTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: UberColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: UberColors.body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isDiscount = false, bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (isBold
                    ? UberTypography.bodySmStrong
                    : UberTypography.caption)
                .copyWith(
              color: isHighlight
                  ? UberColors.accentBlue
                  : (isDiscount ? UberColors.accentGreen : UberColors.body),
            ),
          ),
          Text(
            value,
            style: (isBold
                    ? UberTypography.bodySmStrong
                    : UberTypography.caption)
                .copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight
                  ? UberColors.accentBlue
                  : (isDiscount
                      ? UberColors.accentGreen
                      : (isBold ? UberColors.ink : UberColors.body)),
            ),
          ),
        ],
      ),
    );
  }
}
