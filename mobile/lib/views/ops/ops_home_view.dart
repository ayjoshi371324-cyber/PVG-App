import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/uber_card.dart';

class OpsHomeView extends StatelessWidget {
  const OpsHomeView({super.key});

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
                      Icons.analytics_outlined,
                      size: 64,
                      color: UberColors.mute.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: UberSpacing.sm),
                    Text(
                      'Fleet Operations & Dispatch Console',
                      style: UberTypography.displaySm.copyWith(
                        color: UberColors.hairlineMid,
                      ),
                    ),
                    const SizedBox(height: UberSpacing.xs),
                    Text(
                      'Live dynamic batch intake & Shapley optimization metrics',
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
                  label: 'Fleet Active',
                  value: '12/12',
                  icon: Icons.electric_car_rounded,
                  variant: MetricBadgeVariant.neutral,
                  compact: true,
                ),
                MetricBadge(
                  label: 'Batch Tick',
                  value: '00:15s',
                  icon: Icons.timer_outlined,
                  variant: MetricBadgeVariant.dark,
                  compact: true,
                ),
              ],
            ),
          ),

          // Persistent Operations Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomDrawerSheet(
              title: 'Dynamic Intake Queue',
              subtitle: '6 pending requests awaiting batch optimization tick',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: UberCard(
                          variant: UberCardVariant.tinted,
                          padding: const EdgeInsets.all(UberSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Fleet Savings', style: UberTypography.caption),
                              const SizedBox(height: 2),
                              Text('38.2%', style: UberTypography.displaySm.copyWith(color: UberColors.accentGreen)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: UberSpacing.md),
                      Expanded(
                        child: UberCard(
                          variant: UberCardVariant.tinted,
                          padding: const EdgeInsets.all(UberSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Max Detour', style: UberTypography.caption),
                              const SizedBox(height: 2),
                              Text('11.4%', style: UberTypography.displaySm.copyWith(color: UberColors.accentGreen)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: UberSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          label: 'Trigger Batch Now',
                          size: PillButtonSize.large,
                          variant: PillButtonVariant.primary,
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: UberSpacing.sm),
                      PillButton(
                        label: 'Inject +5',
                        size: PillButtonSize.large,
                        variant: PillButtonVariant.secondary,
                        icon: Icons.add_rounded,
                        onPressed: () {},
                      ),
                    ],
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
