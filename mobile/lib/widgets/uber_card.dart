import 'package:flutter/material.dart';
import 'package:ridepool_app/core/theme.dart';

enum UberCardVariant {
  standard,
  elevated,
  tinted,
  dark,
}

class UberCard extends StatelessWidget {
  const UberCard({
    super.key,
    required this.child,
    this.variant = UberCardVariant.standard,
    this.padding = const EdgeInsets.all(UberSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final UberCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Border? border;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case UberCardVariant.standard:
        backgroundColor = UberColors.canvas;
        border = Border.all(color: UberColors.canvasSoft, width: 1.0);
        boxShadow = null;
        break;
      case UberCardVariant.elevated:
        backgroundColor = UberColors.canvas;
        border = null;
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case UberCardVariant.tinted:
        backgroundColor = UberColors.canvasSoft;
        border = null;
        boxShadow = null;
        break;
      case UberCardVariant.dark:
        backgroundColor = UberColors.blackElevated;
        border = null;
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ];
        break;
    }

    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: UberRadii.xl,
        border: border,
        boxShadow: boxShadow,
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: UberRadii.xl,
        child: InkWell(
          onTap: onTap,
          borderRadius: UberRadii.xl,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
