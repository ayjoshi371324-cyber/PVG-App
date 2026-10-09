import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class PartySizeSelector extends StatelessWidget {
  const PartySizeSelector({
    super.key,
    required this.partySize,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int partySize;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final canDecrement = partySize > 1 && onDecrement != null;
    final canIncrement = partySize < 3 && onIncrement != null;

    final seatText = partySize == 1 ? '1 Seat' : '$partySize Seats';

    return UberCard(
      variant: UberCardVariant.tinted,
      padding: const EdgeInsets.symmetric(
        horizontal: UberSpacing.lg,
        vertical: UberSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.airline_seat_recline_normal_rounded,
                color: UberColors.ink,
                size: 20,
              ),
              const SizedBox(width: UberSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seatText,
                    style: UberTypography.bodyMdStrong,
                  ),
                  Text(
                    'Party size (1–3 passengers)',
                    style: UberTypography.caption,
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: canDecrement ? UberColors.canvas : UberColors.canvasSoft,
                  borderRadius: UberRadii.pill,
                  border: Border.all(
                    color: canDecrement ? UberColors.mute.withValues(alpha: 0.5) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  key: const Key('party_size_decrement_button'),
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  color: canDecrement ? UberColors.ink : UberColors.mute,
                  onPressed: canDecrement ? onDecrement : null,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: UberSpacing.md),
                child: Text(
                  '$partySize',
                  style: UberTypography.bodyMdStrong.copyWith(fontSize: 16),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: canIncrement ? UberColors.canvas : UberColors.canvasSoft,
                  borderRadius: UberRadii.pill,
                  border: Border.all(
                    color: canIncrement ? UberColors.mute.withValues(alpha: 0.5) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  key: const Key('party_size_increment_button'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  color: canIncrement ? UberColors.ink : UberColors.mute,
                  onPressed: canIncrement ? onIncrement : null,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
