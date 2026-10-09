import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

/// Drawer sheet displaying locally persisted past rides with expandable
/// explainable fare receipts and Shapley coalition breakdowns.
class TripHistorySheet extends StatefulWidget {
  const TripHistorySheet({
    super.key,
    required this.history,
    required this.onClose,
  });

  final List<TripReceipt> history;
  final VoidCallback onClose;

  @override
  State<TripHistorySheet> createState() => _TripHistorySheetState();
}

class _TripHistorySheetState extends State<TripHistorySheet> {
  String? _expandedReceiptId;

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
    return BottomDrawerSheet(
      title: 'Past Rides & Receipts',
      subtitle: '${widget.history.length} completed journeys saved locally',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Close button bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                key: const Key('close_history_button'),
                icon: const Icon(Icons.close_rounded, color: UberColors.ink),
                onPressed: widget.onClose,
                tooltip: 'Close history',
              ),
            ],
          ),

          if (widget.history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UberSpacing.xxl),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: UberColors.canvasSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 28,
                      color: UberColors.mute,
                    ),
                  ),
                  const SizedBox(height: UberSpacing.md),
                  Text(
                    'No Past Rides Yet',
                    style: UberTypography.bodyMdStrong,
                  ),
                  const SizedBox(height: UberSpacing.xxs),
                  Text(
                    'Your completed pooling rides will appear here with audited Shapley savings.',
                    textAlign: TextAlign.center,
                    style: UberTypography.caption.copyWith(
                      color: UberColors.body,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.history.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: UberSpacing.sm),
                itemBuilder: (context, index) {
                  final receipt = widget.history[index];
                  final isExpanded = _expandedReceiptId == receipt.receiptId;

                  return UberCard(
                    key: Key('history_item_${receipt.receiptId}'),
                    variant: UberCardVariant.elevated,
                    padding: const EdgeInsets.all(UberSpacing.md),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expandedReceiptId =
                              isExpanded ? null : receipt.receiptId;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top row: Route and Final Fare
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${receipt.pickup.name} → ${receipt.dropoff.name}',
                                      style: UberTypography.bodyMdStrong,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDateTime(receipt.completedAt),
                                      style: UberTypography.caption.copyWith(
                                        color: UberColors.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${receipt.finalPayableFare.round()}',
                                    style: UberTypography.bodyLg.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: UberColors.ink,
                                    ),
                                  ),
                                  Text(
                                    'Save ₹${receipt.savings.round()}',
                                    style: UberTypography.caption.copyWith(
                                      color: UberColors.accentGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: UberSpacing.xs),

                          // Secondary badges row: Environmental impact & Detour
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: UberSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: const BoxDecoration(
                                  color: UberColors.accentGreenSoft,
                                  borderRadius: UberRadii.pill,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.eco_rounded,
                                      size: 12,
                                      color: UberColors.accentGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${receipt.environmentalImpact.co2SavedKg.toStringAsFixed(1)} kg CO₂ saved',
                                      style: UberTypography.caption.copyWith(
                                        color: UberColors.accentGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 20,
                                color: UberColors.body,
                              ),
                            ],
                          ),

                          // Detailed expansion view
                          if (isExpanded) ...[
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
                                    '${receipt.vehicleModel} (${receipt.licensePlate}) • Driver: ${receipt.driverName}',
                                    style: UberTypography.caption.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: UberSpacing.xs),
                            Text(
                              'Detour: +${receipt.finalDetourPercentage.toStringAsFixed(1)}% (Guaranteed ≤ 15%)',
                              style: UberTypography.caption.copyWith(
                                color: UberColors.body,
                              ),
                            ),
                            const SizedBox(height: UberSpacing.sm),
                            Text(
                              'Shapley Cost Allocation Audit',
                              style: UberTypography.bodySmStrong,
                            ),
                            const SizedBox(height: UberSpacing.xxs),
                            for (final audit in receipt.coalitionAudits) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      audit.isUser
                                          ? '${audit.passengerName} (You)'
                                          : audit.passengerName,
                                      style: UberTypography.caption.copyWith(
                                        color: audit.isUser
                                            ? UberColors.accentGreen
                                            : UberColors.ink,
                                        fontWeight: audit.isUser
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '₹${audit.shapleyFairShare.round()} (MC: ₹${audit.marginalContribution.round()})',
                                      style: UberTypography.caption.copyWith(
                                        color: UberColors.body,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
