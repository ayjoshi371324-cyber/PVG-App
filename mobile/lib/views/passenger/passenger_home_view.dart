import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class PassengerHomeView extends StatelessWidget {
  const PassengerHomeView({super.key});

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
                      Icons.map_outlined,
                      size: 64,
                      color: UberColors.mute.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: UberSpacing.sm),
                    Text(
                      'Pune Metro Road Network',
                      style: UberTypography.displaySm.copyWith(
                        color: UberColors.hairlineMid,
                      ),
                    ),
                    const SizedBox(height: UberSpacing.xs),
                    Text(
                      'Ready for dynamic batch matching & Shapley splitting',
                      style: UberTypography.bodySm,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Upper floating status badges
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
                  label: 'Detour Ceiling',
                  value: '≤ 15%',
                  icon: Icons.verified_user_outlined,
                  variant: MetricBadgeVariant.success,
                  compact: true,
                ),
                MetricBadge(
                  label: 'Pricing',
                  value: 'Shapley Split',
                  icon: Icons.savings_outlined,
                  variant: MetricBadgeVariant.neutral,
                  compact: true,
                ),
              ],
            ),
          ),

          // Persistent Bottom Drawer Sheet for Route Booking
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomDrawerSheet(
              title: 'Where to in Pune?',
              subtitle: 'Guaranteed detour ceiling & fair split pricing',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UberCard(
                    variant: UberCardVariant.tinted,
                    padding: const EdgeInsets.all(UberSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: UberColors.ink,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: UberSpacing.md),
                            Expanded(
                              child: Text(
                                'Kothrud Stand (Preset Pickup)',
                                style: UberTypography.bodyMdStrong,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.5),
                          child: Container(
                            height: 16,
                            width: 1.5,
                            color: UberColors.mute,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: UberColors.ink,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                            const SizedBox(width: UberSpacing.md),
                            Expanded(
                              child: Text(
                                'Hinjawadi Phase 1 (Drop-off)',
                                style: UberTypography.bodyMdStrong,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UberSpacing.md),
                  PillButton(
                    label: 'Request Pooled Ride',
                    size: PillButtonSize.large,
                    fullWidth: true,
                    icon: Icons.directions_car_filled_rounded,
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
