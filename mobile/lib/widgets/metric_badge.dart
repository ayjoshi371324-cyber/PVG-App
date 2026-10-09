import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';

enum MetricBadgeVariant {
  neutral,
  success,
  warning,
  alert,
  dark,
}

class MetricBadge extends StatelessWidget {
  const MetricBadge({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.variant = MetricBadgeVariant.neutral,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final MetricBadgeVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (variant) {
      case MetricBadgeVariant.neutral:
        backgroundColor = UberColors.canvasSoft;
        textColor = UberColors.ink;
        iconColor = UberColors.body;
        break;
      case MetricBadgeVariant.success:
        backgroundColor = UberColors.accentGreenSoft;
        textColor = UberColors.accentGreen;
        iconColor = UberColors.accentGreen;
        break;
      case MetricBadgeVariant.warning:
        backgroundColor = UberColors.accentOrangeSoft;
        textColor = UberColors.accentOrange;
        iconColor = UberColors.accentOrange;
        break;
      case MetricBadgeVariant.alert:
        backgroundColor = UberColors.accentRedSoft;
        textColor = UberColors.accentRed;
        iconColor = UberColors.accentRed;
        break;
      case MetricBadgeVariant.dark:
        backgroundColor = UberColors.blackElevated;
        textColor = UberColors.onDark;
        iconColor = UberColors.onDark;
        break;
    }

    final displayText = label.isNotEmpty ? '$label: $value' : value;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: UberRadii.pill,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? UberSpacing.sm : UberSpacing.md,
        vertical: compact ? UberSpacing.xxs : UberSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12.0 : 14.0,
              color: iconColor,
            ),
            SizedBox(width: compact ? UberSpacing.xxs : UberSpacing.xs),
          ],
          Text(
            displayText,
            style: (compact ? UberTypography.caption : UberTypography.bodySmStrong)
                .copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
