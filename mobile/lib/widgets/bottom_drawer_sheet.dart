import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';

class BottomDrawerSheet extends StatelessWidget {
  const BottomDrawerSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.showHandle = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: UberSpacing.xl,
      vertical: UberSpacing.md,
    ),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UberColors.canvas,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24.0,
            offset: const Offset(0, -6),
          ),
        ],
        border: const Border(
          top: BorderSide(color: UberColors.canvasSoft, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) ...[
              const SizedBox(height: UberSpacing.sm),
              Center(
                child: Container(
                  key: const Key('drawer_drag_handle'),
                  width: 44.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: UberColors.mute.withValues(alpha: 0.5),
                    borderRadius: UberRadii.pill,
                  ),
                ),
              ),
              const SizedBox(height: UberSpacing.sm),
            ],
            if (title != null || trailing != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UberSpacing.xl,
                  vertical: UberSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: UberTypography.displaySm,
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: UberTypography.bodySm,
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
