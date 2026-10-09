import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Comprehensive Uber-styled final trip receipt screen displaying:
/// - Hero final payable fare & Shapley pool discount
/// - Route endpoints and completed time
/// - Driver & vehicle details
/// - Environmental impact (CO2 & vehicle-km reduction)
/// - Expandable Shapley coalition audit table
class TripReceiptCard extends StatefulWidget {
  const TripReceiptCard({
    super.key,
    required this.receipt,
    required this.onDone,
    this.initiallyExpanded = false,
  });

  final TripReceipt receipt;
  final VoidCallback onDone;
  final bool initiallyExpanded;

  @override
  State<TripReceiptCard> createState() => _TripReceiptCardState();
}

class _TripReceiptCardState extends State<TripReceiptCard> {
  late bool _isAuditExpanded;

  @override
  void initState() {
    super.initState();
    _isAuditExpanded = widget.initiallyExpanded;
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    final finalRounded = receipt.finalPayableFare.round();
    final soloRounded = receipt.soloReferenceFare.round();
    final savingsRounded = receipt.savings.round();
    final savingsPercentRounded = receipt.savingsPercentage.round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Completion Header
        Center(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: UberColors.accentGreenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: UberColors.accentGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: UberSpacing.xs),
              Text(
                'Arrived at Destination',
                style: UberTypography.displaySm.copyWith(
                  fontWeight: FontWeight.w800,
                  color: UberColors.ink,
                ),
              ),
              Text(
                _formatDateTime(receipt.completedAt),
                style: UberTypography.caption.copyWith(
                  color: UberColors.body,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.md),

        // Main Payable Fare & Savings Hero Card
        UberCard(
          variant: UberCardVariant.elevated,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            children: [
              Text(
                'FINAL CHARGE',
                style: UberTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: UberColors.body,
                ),
              ),
              const SizedBox(height: UberSpacing.xxs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹$finalRounded',
                    style: UberTypography.displayMd.copyWith(
                      fontWeight: FontWeight.w900,
                      color: UberColors.ink,
                    ),
                  ),
                  const SizedBox(width: UberSpacing.sm),
                  Text(
                    '₹$soloRounded',
                    style: UberTypography.bodyLg.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: UberColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UberSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.md,
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
                  'Save ₹$savingsRounded ($savingsPercentRounded% off with Shapley pool)',
                  style: UberTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: UberColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.sm),

        // Route & Driver summary
        UberCard(
          variant: UberCardVariant.tinted,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: UberColors.ink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: UberSpacing.sm),
                  Expanded(
                    child: Text(
                      receipt.pickup.name,
                      style: UberTypography.bodySmStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3.5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 12,
                    width: 1.5,
                    color: UberColors.mute,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: UberColors.ink,
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  const SizedBox(width: UberSpacing.sm),
                  Expanded(
                    child: Text(
                      receipt.dropoff.name,
                      style: UberTypography.bodySmStrong,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: UberSpacing.lg),
              Row(
                children: [
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 16,
                    color: UberColors.body,
                  ),
                  const SizedBox(width: UberSpacing.xs),
                  Expanded(
                    child: Text(
                      '${receipt.vehicleModel} (${receipt.licensePlate}) • ${receipt.driverName}',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.body,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.sm),

        // Environmental Impact & Detour Guarantee Metrics
        Row(
          children: [
            Expanded(
              child: UberCard(
                variant: UberCardVariant.tinted,
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.sm,
                  vertical: UberSpacing.md,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: UberColors.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(height: UberSpacing.xxs),
                    Text(
                      '${receipt.environmentalImpact.co2SavedKg.toStringAsFixed(1)} kg CO₂',
                      style: UberTypography.bodyMdStrong.copyWith(
                        color: UberColors.accentGreen,
                      ),
                    ),
                    Text(
                      '${receipt.environmentalImpact.vehicleKmSaved.toStringAsFixed(1)} km pooled',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: UberSpacing.sm),
            Expanded(
              child: UberCard(
                variant: UberCardVariant.tinted,
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.sm,
                  vertical: UberSpacing.md,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: UberColors.accentGreen,
                      size: 20,
                    ),
                    const SizedBox(height: UberSpacing.xxs),
                    Text(
                      '+${receipt.finalDetourPercentage.toStringAsFixed(1)}%',
                      style: UberTypography.bodyMdStrong.copyWith(
                        color: UberColors.ink,
                      ),
                    ),
                    Text(
                      '≤ 15.0% Guaranteed',
                      style: UberTypography.caption.copyWith(
                        color: UberColors.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: UberSpacing.sm),

        // Expandable Shapley Coalition Audit Card
        UberCard(
          variant: UberCardVariant.elevated,
          padding: const EdgeInsets.all(UberSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const Key('shapley_audit_toggle'),
                onTap: () {
                  setState(() {
                    _isAuditExpanded = !_isAuditExpanded;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
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
                            'Shapley Cost Allocation Audit',
                            style: UberTypography.bodyMdStrong,
                          ),
                          Text(
                            'Marginal cost contribution per passenger',
                            style: UberTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isAuditExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: UberColors.body,
                    ),
                  ],
                ),
              ),

              if (_isAuditExpanded) ...[
                const Divider(height: UberSpacing.lg),
                Text(
                  'Cooperative game theory calculates each rider’s fair charge proportional to their marginal detour contribution, guaranteeing stability and no cross-subsidies.',
                  style: UberTypography.caption.copyWith(
                    color: UberColors.body,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: UberSpacing.sm),
                for (final audit in receipt.coalitionAudits) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: UberSpacing.xs),
                    padding: const EdgeInsets.all(UberSpacing.sm),
                    decoration: BoxDecoration(
                      color: audit.isUser
                          ? UberColors.accentGreenSoft
                          : UberColors.canvasSoft,
                      borderRadius: UberRadii.md,
                      border: audit.isUser
                          ? Border.all(
                              color: UberColors.accentGreen.withValues(alpha: 0.3),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audit.isUser
                                  ? '${audit.passengerName} (User)'
                                  : audit.passengerName,
                              style: UberTypography.bodySmStrong.copyWith(
                                color: audit.isUser
                                    ? UberColors.accentGreen
                                    : UberColors.ink,
                              ),
                            ),
                            Text(
                              'MC: ₹${audit.marginalContribution.round()} • Solo: ₹${audit.soloFare.round()}',
                              style: UberTypography.caption.copyWith(
                                color: UberColors.body,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Fair Share: ₹${audit.shapleyFairShare.round()}',
                              style: UberTypography.bodySmStrong,
                            ),
                            Text(
                              '-₹${audit.savings.round()}',
                              style: UberTypography.caption.copyWith(
                                color: UberColors.accentGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: UberSpacing.md),

        // Done button
        PillButton(
          key: const Key('receipt_done_button'),
          label: 'Book Another Ride',
          size: PillButtonSize.large,
          fullWidth: true,
          variant: PillButtonVariant.primary,
          icon: Icons.check_rounded,
          onPressed: widget.onDone,
        ),
      ],
    );
  }
}
