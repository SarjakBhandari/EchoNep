import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 28;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

class AppPalette extends ThemeExtension<AppPalette> {
  final Color surfaceCard;
  final Color surfaceCardAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color gradientStart;
  final Color gradientMid;
  final Color errorColor;
  final Color errorBg;

  const AppPalette({
    required this.surfaceCard,
    required this.surfaceCardAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientStart,
    required this.gradientMid,
    required this.errorColor,
    required this.errorBg,
  });

  static const light = AppPalette(
    surfaceCard: Color(0xFFFFFBF5),
    surfaceCardAlt: Color(0xFFFFF7EF),
    textPrimary: Color(0xFF062A3A),
    textSecondary: Color(0xFF6B6B6B),
    gradientStart: Color(0xFFFFFCF5),
    gradientMid: Color(0xFFF5E8D8),
    errorColor: Color(0xFFB3261E),
    errorBg: Color(0xFFFDECEA),
  );

  static const dark = AppPalette(
    surfaceCard: Color(0xFF15232B),
    surfaceCardAlt: Color(0xFF1B2C36),
    textPrimary: Color(0xFFF2F4F5),
    textSecondary: Color(0xFFA8B3B8),
    gradientStart: Color(0xFF0B161C),
    gradientMid: Color(0xFF13262F),
    errorColor: Color(0xFFFFB4AB),
    errorBg: Color(0xFF3B1613),
  );

  @override
  AppPalette copyWith({
    Color? surfaceCard,
    Color? surfaceCardAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? gradientStart,
    Color? gradientMid,
    Color? errorColor,
    Color? errorBg,
  }) {
    return AppPalette(
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardAlt: surfaceCardAlt ?? this.surfaceCardAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMid: gradientMid ?? this.gradientMid,
      errorColor: errorColor ?? this.errorColor,
      errorBg: errorBg ?? this.errorBg,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceCardAlt: Color.lerp(surfaceCardAlt, other.surfaceCardAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMid: Color.lerp(gradientMid, other.gradientMid, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const seedColor = Color(0xFF0B6E99);

  static TextTheme _textTheme(Color baseColor) {
    return TextTheme(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.manrope(
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.manrope(color: baseColor),
      bodyMedium: GoogleFonts.manrope(color: baseColor),
    );
  }

  static ThemeData get light {
    const palette = AppPalette.light;
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      scaffoldBackgroundColor: palette.gradientStart,
      useMaterial3: true,
      textTheme: _textTheme(palette.textPrimary),
      extensions: const [palette],
    );
  }

  static ThemeData get dark {
    const palette = AppPalette.dark;
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: palette.gradientStart,
      useMaterial3: true,
      textTheme: _textTheme(palette.textPrimary),
      extensions: const [palette],
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
