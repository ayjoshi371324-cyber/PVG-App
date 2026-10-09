import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';

void main() {
  group('UberTheme Tokens', () {
    test('UberColors match DESIGN-uber.md palette', () {
      expect(UberColors.primary, const Color(0xFF000000));
      expect(UberColors.onPrimary, const Color(0xFFFFFFFF));
      expect(UberColors.ink, const Color(0xFF000000));
      expect(UberColors.body, const Color(0xFF5E5E5E));
      expect(UberColors.mute, const Color(0xFFAFAFAF));
      expect(UberColors.hairlineMid, const Color(0xFF4B4B4B));
      expect(UberColors.canvas, const Color(0xFFFFFFFF));
      expect(UberColors.canvasSoft, const Color(0xFFEFEFEF));
      expect(UberColors.canvasSofter, const Color(0xFFF3F3F3));
      expect(UberColors.surfacePressed, const Color(0xFFE2E2E2));
      expect(UberColors.link, const Color(0xFF0000EE));
      expect(UberColors.onDark, const Color(0xFFFFFFFF));
      expect(UberColors.blackElevated, const Color(0xFF282828));
    });

    test('UberRadii match DESIGN-uber.md geometries', () {
      expect(UberRadii.none, BorderRadius.zero);
      expect(UberRadii.md, BorderRadius.circular(8.0));
      expect(UberRadii.lg, BorderRadius.circular(12.0));
      expect(UberRadii.xl, BorderRadius.circular(16.0));
      expect(UberRadii.pill, BorderRadius.circular(999.0));
      expect(UberRadii.pillTab, BorderRadius.circular(36.0));
      expect(UberRadii.full, BorderRadius.circular(9999.0));
    });

    test('UberSpacing matches DESIGN-uber.md spacing scale', () {
      expect(UberSpacing.xxs, 4.0);
      expect(UberSpacing.xs, 6.0);
      expect(UberSpacing.sm, 8.0);
      expect(UberSpacing.md, 12.0);
      expect(UberSpacing.lg, 16.0);
      expect(UberSpacing.xl, 20.0);
      expect(UberSpacing.xxl, 24.0);
      expect(UberSpacing.xxxl, 32.0);
    });

    test('UberTheme lightTheme generates valid high-contrast ThemeData', () {
      final theme = UberTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, equals(UberColors.canvas));
      expect(theme.colorScheme.primary, equals(UberColors.primary));
      expect(theme.colorScheme.surface, equals(UberColors.canvas));
      expect(theme.colorScheme.onPrimary, equals(UberColors.onPrimary));
    });
  });
}
