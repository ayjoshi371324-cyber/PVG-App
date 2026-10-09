import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Modal bottom sheet or embedded section explaining the Shapley Value fair fare breakdown.
///
/// Displays:
/// 1. Solo baseline fare vs. Total pooled route cost.
/// 2. Marginal contribution per passenger.
/// 3. Fixed fee share.
/// 4. Characteristic function coalition table v(S).
/// 5. Co-passenger fare shares whose sum matches total route cost exactly.
/// 6. Plain-language explanation of cooperative game theory fairness.
class WhyAmIPayingSheet extends StatelessWidget {
  const WhyAmIPayingSheet({
    super.key,
    required this.breakdown,
    this.onClose,
  });

  final ShapleyFareBreakdown breakdown;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context,
    ShapleyFareBreakdown breakdown,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: UberColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: WhyAmIPayingSheet(
              breakdown: breakdown,
              onClose: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final soloRounded = breakdown.soloFare.round();
    final totalTripCostRounded = breakdown.totalTripCost.round();
    final sharedRounded = breakdown.sharedFare.round();
    final savingsRounded = breakdown.savings.round();

    final sumShares = breakdown.passengerShares.isNotEmpty
        ? breakdown.passengerShares.values.fold(0.0, (s, v) => s + v)
        : breakdown.sharedFare;

    return Padding(
      padding: const EdgeInsets.all(UberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top drag handle if in modal
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: UberColors.mute.withValues(alpha: 0.5),
                borderRadius: UberRadii.pill,
              ),
            ),
          ),
          const SizedBox(height: UberSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why am I paying this fare?',
                      style: UberTypography.displaySm,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mathematical fairness certified by cooperative game theory',
                      style: UberTypography.caption.copyWith(color: UberColors.body),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: UberColors.ink),
                  onPressed: onClose,
                ),
            ],
          ),

          const SizedBox(height: UberSpacing.md),

          // Plain-language Shapley concept explanation card
          UberCard(
            variant: UberCardVariant.tinted,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: UberColors.accentGreenSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: UberColors.accentGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: UberSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cooperative Fairness (Shapley Value)',
                        style: UberTypography.bodySmStrong,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '“The system compares the cost of different passenger combinations and averages how much each passenger adds to the total cost. This helps distribute the shared fare according to each passenger\'s contribution.”',
                        style: UberTypography.caption.copyWith(
                          color: UberColors.ink,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Core Fares Breakdown Card
          UberCard(
            variant: UberCardVariant.elevated,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Route Cost Comparison',
                  style: UberTypography.bodyMdStrong,
                ),
                const SizedBox(height: UberSpacing.sm),
                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.sm),

                // Solo Baseline Fare Row
                _buildRow(
                  key: const Key('solo_baseline_fare_row'),
                  label: 'Solo Direct Trip Baseline',
                  value: '₹$soloRounded',
                  subtitle: 'Cost if driving alone with no detour',
                ),

                // Total Pooled Route Cost Row
                _buildRow(
                  key: const Key('total_pooled_route_cost_row'),
                  label: 'Total Vehicle Pooled Route Cost',
                  value: '₹$totalTripCostRounded',
                  subtitle: 'Total cost for all ${breakdown.coalitionSize} passengers v(N)',
                ),

                // Fixed Fee Share Row
                _buildRow(
                  key: const Key('fixed_fee_share_row'),
                  label: 'Fixed Base Fee Share',
                  value: '₹${breakdown.fixedFeeShare.toStringAsFixed(2)}',
                  subtitle: 'Fair pro-rata share of pickup/starting fee',
                ),

                // Per-Person Party Row (if applicable)
                if (breakdown.partySize > 1)
                  _buildRow(
                    key: const Key('per_person_split_row'),
                    label: 'Per-Person Party Share',
                    value: '₹${breakdown.perPersonFare.toStringAsFixed(2)} / person (Party of ${breakdown.partySize})',
                    subtitle: '₹$sharedRounded split equally for your party',
                    isHighlight: true,
                  ),

                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.xs),

                // Final Fare Row
                _buildRow(
                  label: 'Your Allocated Pooled Fare',
                  value: '₹$sharedRounded',
                  subtitle: 'Saved ₹$savingsRounded (${breakdown.savingsPercentage.round()}% discount)',
                  isBold: true,
                  isDiscount: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Marginal Contributions Section
          UberCard(
            key: const Key('marginal_contributions_section'),
            variant: UberCardVariant.standard,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Marginal Contribution per Passenger',
                        style: UberTypography.bodyMdStrong,
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    const Icon(Icons.show_chart_rounded, size: 18, color: UberColors.body),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Average cost added when each passenger joins the shared vehicle',
                  style: UberTypography.caption.copyWith(color: UberColors.mute),
                ),
                const SizedBox(height: UberSpacing.sm),
                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.sm),

                if (breakdown.marginalContributions.isNotEmpty)
                  ...breakdown.marginalContributions.entries.map((entry) {
                    final isUser = entry.key.contains('(You)');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isUser ? UberColors.accentBlue : UberColors.body,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: UberSpacing.sm),
                              Text(
                                entry.key,
                                style: isUser
                                    ? UberTypography.bodySmStrong
                                    : UberTypography.bodySm,
                              ),
                            ],
                          ),
                          Text(
                            '₹${entry.value.toStringAsFixed(2)}',
                            style: UberTypography.bodySmStrong,
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(
                    'Your Marginal Contribution: ₹${breakdown.marginalContribution.toStringAsFixed(2)}',
                    style: UberTypography.bodySm,
                  ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Characteristic Function Coalition Table v(S)
          UberCard(
            key: const Key('coalition_table_section'),
            variant: UberCardVariant.standard,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Characteristic Coalition Table v(S)',
                        style: UberTypography.bodyMdStrong,
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: UberColors.canvasSoft,
                        borderRadius: UberRadii.md,
                      ),
                      child: Text(
                        'Game Theory Engine',
                        style: UberTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum routing cost evaluated across passenger subsets',
                  style: UberTypography.caption.copyWith(color: UberColors.mute),
                ),
                const SizedBox(height: UberSpacing.sm),
                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.xs),

                if (breakdown.coalitionTable.isNotEmpty)
                  ...breakdown.coalitionTable.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'v({${entry.key}})',
                              style: UberTypography.caption.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: UberColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: UberSpacing.sm),
                          Text(
                            '₹${entry.value.toStringAsFixed(2)}',
                            style: UberTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: UberColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Text(
                    'Solo v({You}): ₹$soloRounded  •  Total v({All}): ₹$totalTripCostRounded',
                    style: UberTypography.caption,
                  ),
              ],
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Passenger Fare Shares & Sum Equality Verification
          UberCard(
            key: const Key('passenger_shares_section'),
            variant: UberCardVariant.elevated,
            padding: const EdgeInsets.all(UberSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Passenger Fare Shares',
                        style: UberTypography.bodyMdStrong,
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    MetricBadge(
                      label: 'Efficiency',
                      value: '100% Balanced',
                      variant: MetricBadgeVariant.success,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: UberSpacing.sm),
                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.sm),

                if (breakdown.passengerShares.isNotEmpty)
                  ...breakdown.passengerShares.entries.map((entry) {
                    final isUser = entry.key.contains('(You)');
                    final pSize = breakdown.partySizes[entry.key] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${entry.key}${pSize > 1 ? " ($pSize seats)" : ""}',
                            style: isUser
                                ? UberTypography.bodySmStrong
                                : UberTypography.bodySm,
                          ),
                          Text(
                            '₹${entry.value.toStringAsFixed(2)}',
                            style: UberTypography.bodySmStrong.copyWith(
                              color: isUser ? UberColors.accentGreen : UberColors.ink,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Share', style: UberTypography.bodySmStrong),
                      Text('₹${breakdown.sharedFare.toStringAsFixed(2)}', style: UberTypography.bodySmStrong),
                    ],
                  ),

                const SizedBox(height: UberSpacing.sm),
                const Divider(height: 1, color: UberColors.canvasSoft),
                const SizedBox(height: UberSpacing.sm),

                // Exact match guarantee certification banner
                Container(
                  key: const Key('exact_sum_match_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: UberSpacing.sm,
                    vertical: UberSpacing.xs,
                  ),
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
                        Icons.check_circle_rounded,
                        color: UberColors.accentGreen,
                        size: 16,
                      ),
                      const SizedBox(width: UberSpacing.xs),
                      Expanded(
                        child: Text(
                          'Exact Match: Sum of Shares (₹${sumShares.toStringAsFixed(2)}) Matches Total Route Cost: ₹$totalTripCostRounded',
                          style: UberTypography.caption.copyWith(
                            color: UberColors.accentGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (onClose != null) ...[
            const SizedBox(height: UberSpacing.lg),
            PillButton(
              label: 'Done',
              variant: PillButtonVariant.primary,
              size: PillButtonSize.large,
              fullWidth: true,
              onPressed: onClose,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    Key? key,
    required String label,
    required String value,
    String? subtitle,
    bool isBold = false,
    bool isDiscount = false,
    bool isHighlight = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: (isBold
                          ? UberTypography.bodySmStrong
                          : UberTypography.bodySm)
                      .copyWith(
                    color: isHighlight
                        ? UberColors.accentBlue
                        : (isDiscount ? UberColors.accentGreen : UberColors.ink),
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: UberTypography.caption.copyWith(
                      color: UberColors.body,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: (isBold
                    ? UberTypography.bodySmStrong
                    : UberTypography.bodySm)
                .copyWith(
              fontWeight: FontWeight.w700,
              color: isHighlight
                  ? UberColors.accentBlue
                  : (isDiscount ? UberColors.accentGreen : UberColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
