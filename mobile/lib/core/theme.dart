import 'package:flutter/material.dart';

/// Design tokens inspired by Uber's minimalist black/white duet and geometry
/// as defined in DESIGN-uber.md
class UberColors {
  UberColors._();

  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF000000);
  static const Color body = Color(0xFF5E5E5E);
  static const Color mute = Color(0xFFAFAFAF);
  static const Color hairlineMid = Color(0xFF4B4B4B);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFEFEFEF);
  static const Color canvasSofter = Color(0xFFF3F3F3);
  static const Color surfacePressed = Color(0xFFE2E2E2);
  static const Color link = Color(0xFF0000EE);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color blackElevated = Color(0xFF282828);

  // Semantic Accent Colors for RidePool guarantees
  static const Color accentGreen = Color(0xFF0E8345); // Shapley savings / detour pass
  static const Color accentGreenSoft = Color(0xFFE7F7ED);
  static const Color accentRed = Color(0xFFE11900); // Detour violation / alerts
  static const Color accentRedSoft = Color(0xFFFCEBEB);
  static const Color accentOrange = Color(0xFFFF8800); // Pending/caution
  static const Color accentOrangeSoft = Color(0xFFFFF4E5);
  static const Color accentBlue = Color(0xFF276EF1); // Active route / map
  static const Color accentBlueSoft = Color(0xFFEBF2FD);
}

/// Distinct high-contrast colors assigned to each pooled booking/rider on the live map.
class BookingColors {
  BookingColors._();

  static const Color booking1 = Color(0xFF0066FF); // Rider 1 / You: Royal Blue
  static const Color booking2 = Color(0xFF8B5CF6); // Rider 2: Electric Violet / Purple
  static const Color booking3 = Color(0xFFF97316); // Rider 3: Vivid Amber-Orange
  static const Color booking4 = Color(0xFF059669); // Rider 4: Emerald Green
  static const Color booking5 = Color(0xFFEC4899); // Rider 5: Fuchsia Pink
  static const Color booking6 = Color(0xFF0D9488); // Rider 6: Dark Teal

  static const List<Color> palette = [
    booking1,
    booking2,
    booking3,
    booking4,
    booking5,
    booking6,
  ];

  static Color getColor(int bookingIndex) {
    if (bookingIndex <= 0) return booking1;
    final idx = (bookingIndex - 1) % palette.length;
    return palette[idx];
  }
}

class UberRadii {
  UberRadii._();

  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius md = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999.0));
  static const BorderRadius pillTab = BorderRadius.all(Radius.circular(36.0));
  static const BorderRadius full = BorderRadius.all(Radius.circular(9999.0));
}

class UberSpacing {
  UberSpacing._();

  static const double xxs = 4.0;
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class UberTypography {
  UberTypography._();

  static const String _fontFamily = 'Inter';
  static const List<String> _fontFamilyFallback = [
    'UberMove',
    'UberMoveText',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const TextStyle displayXxl = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 52.0,
    fontWeight: FontWeight.w700,
    height: 64.0 / 52.0,
    color: UberColors.ink,
    letterSpacing: -1.0,
  );

  static const TextStyle displayXl = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 36.0,
    fontWeight: FontWeight.w700,
    height: 44.0 / 36.0,
    color: UberColors.ink,
    letterSpacing: -0.75,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 32.0,
    fontWeight: FontWeight.w700,
    height: 40.0 / 32.0,
    color: UberColors.ink,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    height: 32.0 / 24.0,
    color: UberColors.ink,
    letterSpacing: -0.25,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    height: 28.0 / 20.0,
    color: UberColors.ink,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    height: 24.0 / 18.0,
    color: UberColors.ink,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 24.0 / 16.0,
    color: UberColors.ink,
  );

  static const TextStyle bodyMdStrong = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 20.0 / 16.0,
    color: UberColors.ink,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 20.0 / 14.0,
    color: UberColors.body,
  );

  static const TextStyle bodySmStrong = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 16.0 / 14.0,
    color: UberColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 20.0 / 12.0,
    color: UberColors.body,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 24.0 / 18.0,
    color: UberColors.onPrimary,
  );

  static const TextStyle buttonMd = TextStyle(
    fontFamily: _fontFamily,
    fontFamilyFallback: _fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 20.0 / 16.0,
    color: UberColors.onPrimary,
  );
}

class UberTheme {
  UberTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: UberColors.canvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: UberColors.primary,
        onPrimary: UberColors.onPrimary,
        secondary: UberColors.blackElevated,
        onSecondary: UberColors.onDark,
        surface: UberColors.canvas,
        onSurface: UberColors.ink,
        error: UberColors.accentRed,
        onError: UberColors.onDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: UberColors.canvas,
        foregroundColor: UberColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: UberTypography.displaySm,
      ),
      dividerTheme: const DividerThemeData(
        color: UberColors.canvasSoft,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: UberColors.canvas,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: UberRadii.xl,
          side: BorderSide(color: UberColors.canvasSoft, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UberColors.primary,
          foregroundColor: UberColors.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: UberTypography.buttonMd,
          padding: const EdgeInsets.symmetric(
            horizontal: UberSpacing.xl,
            vertical: UberSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UberColors.canvasSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: UberColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UberSpacing.lg,
          vertical: UberSpacing.md,
        ),
        hintStyle: UberTypography.bodyMd.copyWith(color: UberColors.mute),
      ),
    );
  }
}
