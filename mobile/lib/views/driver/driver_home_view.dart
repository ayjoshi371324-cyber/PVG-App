import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberColors.canvas,
      body: Stack(
        children: [
          // Background simulation canvas / map placeholder
          Positioned.fill(
            child: Container(
              color: UberColors.canvasSofter,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 64,
                      color: UberColors.mute.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: UberSpacing.sm),
                    Text(
                      'Turn-by-Turn Stop Manifest',
                      style: UberTypography.displaySm.copyWith(
                        color: UberColors.hairlineMid,
                      ),
                    ),
                    const SizedBox(height: UberSpacing.xs),
                    Text(
                      'Real-time stop sequencing & cabin occupancy tracking',
                      style: UberTypography.bodySm,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Upper status badges
          Positioned(
            top: UberSpacing.md,
            left: UberSpacing.lg,
            right: UberSpacing.lg,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: UberSpacing.sm,
              runSpacing: UberSpacing.xs,
              children: const [
                MetricBadge(
                  label: 'Cabin',
                  value: '3/4 Seats',
                  icon: Icons.airline_seat_recline_normal_rounded,
                  variant: MetricBadgeVariant.warning,
                  compact: true,
                ),
                MetricBadge(
                  label: 'Shift',
                  value: 'Online',
                  icon: Icons.circle,
                  variant: MetricBadgeVariant.success,
                  compact: true,
                ),
              ],
            ),
          ),

          // Persistent Driver Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomDrawerSheet(
              title: 'Next Stop: Pickup Aakash',
              subtitle: 'Kothrud Stand • ETA 3 mins (0.8 km)',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UberCard(
                    variant: UberCardVariant.tinted,
                    padding: const EdgeInsets.all(UberSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Passenger Verification', style: UberTypography.caption),
                            Text('Aakash S. (1 Seat)', style: UberTypography.bodyMdStrong),
                          ],
                        ),
                        MetricBadge(
                          label: 'Code',
                          value: '#4821',
                          variant: MetricBadgeVariant.dark,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UberSpacing.md),
                  PillButton(
                    label: 'Confirm Passenger Boarded',
                    size: PillButtonSize.large,
                    fullWidth: true,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
