import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';

enum PillButtonVariant {
  primary,
  secondary,
  subtle,
  outline,
  floating,
}

enum PillButtonSize {
  small,
  medium,
  large,
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.primary,
    this.size = PillButtonSize.medium,
    this.fullWidth = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonVariant variant;
  final PillButtonSize size;
  final bool fullWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case PillButtonVariant.primary:
        backgroundColor = isEnabled ? UberColors.primary : UberColors.canvasSoft;
        foregroundColor = isEnabled ? UberColors.onPrimary : UberColors.mute;
        break;
      case PillButtonVariant.secondary:
        backgroundColor = UberColors.canvas;
        foregroundColor = isEnabled ? UberColors.ink : UberColors.mute;
        borderSide = const BorderSide(color: UberColors.canvasSoft, width: 1.5);
        break;
      case PillButtonVariant.subtle:
        backgroundColor = UberColors.canvasSoft;
        foregroundColor = isEnabled ? UberColors.ink : UberColors.mute;
        break;
      case PillButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled ? UberColors.ink : UberColors.mute;
        borderSide = BorderSide(
          color: isEnabled ? UberColors.ink : UberColors.mute,
          width: 1.5,
        );
        break;
      case PillButtonVariant.floating:
        backgroundColor = UberColors.canvas;
        foregroundColor = isEnabled ? UberColors.ink : UberColors.mute;
        break;
    }

    EdgeInsets padding;
    TextStyle textStyle;
    double iconSize;

    switch (size) {
      case PillButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: UberSpacing.md,
          vertical: UberSpacing.xs + 2,
        );
        textStyle = UberTypography.bodySmStrong.copyWith(color: foregroundColor);
        iconSize = 16.0;
        break;
      case PillButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: UberSpacing.xl,
          vertical: UberSpacing.md,
        );
        textStyle = UberTypography.buttonMd.copyWith(color: foregroundColor);
        iconSize = 18.0;
        break;
      case PillButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: UberSpacing.xxl,
          vertical: UberSpacing.lg,
        );
        textStyle = UberTypography.buttonLarge.copyWith(color: foregroundColor);
        iconSize = 22.0;
        break;
    }

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: UberSpacing.sm),
        ],
        Text(label, style: textStyle),
      ],
    );

    return Material(
      color: backgroundColor,
      borderRadius: UberRadii.pill,
      elevation: variant == PillButtonVariant.floating ? 4.0 : 0.0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: UberRadii.pill,
        splashColor: variant == PillButtonVariant.primary
            ? Colors.white.withValues(alpha: 0.15)
            : UberColors.surfacePressed,
        highlightColor: variant == PillButtonVariant.primary
            ? Colors.white.withValues(alpha: 0.08)
            : UberColors.surfacePressed.withValues(alpha: 0.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: UberRadii.pill,
            border: borderSide != BorderSide.none
                ? Border.fromBorderSide(borderSide)
                : null,
          ),
          padding: padding,
          child: content,
        ),
      ),
    );
  }
}
