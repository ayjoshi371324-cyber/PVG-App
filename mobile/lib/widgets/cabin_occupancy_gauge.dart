import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class CabinOccupancyGauge extends StatelessWidget {
  const CabinOccupancyGauge({
    super.key,
    required this.currentOccupancy,
    required this.maxCapacity,
    required this.seats,
    this.compact = false,
    this.onSeatTap,
  });

  final int currentOccupancy;
  final int maxCapacity;
  final List<CabinSeat> seats;
  final bool compact;
  final void Function(CabinSeat seat)? onSeatTap;

  bool get isFull => currentOccupancy >= maxCapacity;

  MetricBadgeVariant get _badgeVariant {
    if (isFull) return MetricBadgeVariant.warning;
    if (currentOccupancy > 0) return MetricBadgeVariant.success;
    return MetricBadgeVariant.dark;
  }

  String get _cabinStatusLabel {
    if (isFull) return 'Cabin Full';
    if (currentOccupancy > 0) return 'Active Load';
    return 'Cabin Available';
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return MetricBadge(
        label: 'Cabin',
        value: '$currentOccupancy/$maxCapacity Seats',
        icon: Icons.airline_seat_recline_normal_rounded,
        variant: _badgeVariant,
        compact: true,
      );
    }

    return UberCard(
      variant: UberCardVariant.elevated,
      padding: const EdgeInsets.all(UberSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(UberSpacing.xs),
                    decoration: BoxDecoration(
                      color: isFull
                          ? UberColors.accentOrangeSoft
                          : UberColors.canvasSoft,
                      borderRadius: UberRadii.md,
                    ),
                    child: Icon(
                      Icons.airline_seat_recline_normal_rounded,
                      size: 18,
                      color: isFull ? UberColors.accentOrange : UberColors.ink,
                    ),
                  ),
                  const SizedBox(width: UberSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cabin Occupancy',
                        style: UberTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _cabinStatusLabel,
                        style: UberTypography.bodySmStrong.copyWith(
                          color: isFull
                              ? UberColors.accentOrange
                              : UberColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              MetricBadge(
                label: '',
                value: '$currentOccupancy/$maxCapacity Seats',
                variant: _badgeVariant,
                compact: true,
              ),
            ],
          ),

          const SizedBox(height: UberSpacing.sm),

          // Linear Occupancy Gauge Bar
          ClipRRect(
            borderRadius: UberRadii.pill,
            child: LinearProgressIndicator(
              value: maxCapacity > 0 ? (currentOccupancy / maxCapacity).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: UberColors.canvasSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull
                    ? UberColors.accentOrange
                    : (currentOccupancy > 0 ? UberColors.ink : UberColors.mute),
              ),
            ),
          ),

          const SizedBox(height: UberSpacing.md),

          // Vehicle Cabin Seat Blueprint
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UberSpacing.md,
              vertical: UberSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: UberColors.canvasSofter,
              borderRadius: UberRadii.lg,
              border: Border.all(color: UberColors.canvasSoft),
            ),
            child: Column(
              children: [
                // Front Row: Driver & Front Passenger (Seat 0)
                Row(
                  children: [
                    Expanded(
                      child: _buildDriverSeatTile(),
                    ),
                    const SizedBox(width: UberSpacing.sm),
                    Expanded(
                      child: _buildPassengerSeatTile(
                        seats.isNotEmpty ? seats[0] : null,
                        key: const Key('cabin_seat_0'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UberSpacing.sm),

                // Rear Row: Rear L, Rear C, Rear R
                Row(
                  children: [
                    Expanded(
                      child: _buildPassengerSeatTile(
                        seats.length > 1 ? seats[1] : null,
                        key: const Key('cabin_seat_1'),
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    Expanded(
                      child: _buildPassengerSeatTile(
                        seats.length > 2 ? seats[2] : null,
                        key: const Key('cabin_seat_2'),
                      ),
                    ),
                    const SizedBox(width: UberSpacing.xs),
                    Expanded(
                      child: _buildPassengerSeatTile(
                        seats.length > 3 ? seats[3] : null,
                        key: const Key('cabin_seat_3'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSeatTile() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UberSpacing.sm,
        vertical: UberSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: UberColors.surfacePressed,
        borderRadius: UberRadii.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_motorsports_rounded,
            size: 16,
            color: UberColors.body,
          ),
          const SizedBox(width: UberSpacing.xxs),
          Text(
            'Driver',
            style: UberTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: UberColors.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerSeatTile(CabinSeat? seat, {required Key key}) {
    if (seat == null) return const SizedBox.shrink();

    final isOccupied = seat.isOccupied;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        borderRadius: UberRadii.md,
        onTap: onSeatTap != null ? () => onSeatTap!(seat) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: UberSpacing.xs,
            vertical: UberSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isOccupied ? UberColors.ink : UberColors.canvas,
            borderRadius: UberRadii.md,
            border: Border.all(
              color: isOccupied ? UberColors.ink : UberColors.mute.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOccupied ? Icons.person_rounded : Icons.person_outline_rounded,
                    size: 13,
                    color: isOccupied ? UberColors.onPrimary : UberColors.mute,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    seat.label,
                    style: UberTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isOccupied ? UberColors.onPrimary : UberColors.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isOccupied ? (seat.passengerName ?? 'Occupied') : 'Empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UberTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: isOccupied ? FontWeight.w700 : FontWeight.w400,
                  color: isOccupied ? UberColors.onPrimary : UberColors.mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
