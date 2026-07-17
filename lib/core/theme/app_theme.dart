import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FestivalThemePack {
  const FestivalThemePack({
    required this.name,
    required this.primary,
    required this.accent,
    required this.lightBackground,
    required this.darkBackground,
    required this.surfaceTint,
    required this.heroGradient,
  });

  final String name;
  final Color primary;
  final Color accent;
  final Color lightBackground;
  final Color darkBackground;
  final Color surfaceTint;
  final List<Color> heroGradient;
}

class AppTheme {
  const AppTheme._();

  static const List<FestivalThemePack> packs = <FestivalThemePack>[
    FestivalThemePack(
      name: 'Saffron Dawn',
      primary: Color(0xFFFF6700),
      accent: Color(0xFFFFB800),
      lightBackground: Color(0xFFFFF8F0),
      darkBackground: Color(0xFF0F0A05),
      surfaceTint: Color(0xFFFFF0E3),
      heroGradient: <Color>[
        Color(0xFFFF6700),
        Color(0xFFFFB800),
        Color(0xFF8A2B06),
      ],
    ),
    FestivalThemePack(
      name: 'Diwali Gold',
      primary: Color(0xFFE88B14),
      accent: Color(0xFFFFD36E),
      lightBackground: Color(0xFFFFF7EA),
      darkBackground: Color(0xFF130C06),
      surfaceTint: Color(0xFFFFF0D8),
      heroGradient: <Color>[
        Color(0xFFE88B14),
        Color(0xFFFFD36E),
        Color(0xFF5B2C05),
      ],
    ),
    FestivalThemePack(
      name: 'Monsoon Mehfil',
      primary: Color(0xFF26708D),
      accent: Color(0xFF7CD5F5),
      lightBackground: Color(0xFFF2FBFF),
      darkBackground: Color(0xFF09161C),
      surfaceTint: Color(0xFFDFF6FF),
      heroGradient: <Color>[
        Color(0xFF114A63),
        Color(0xFF26708D),
        Color(0xFF7CD5F5),
      ],
    ),
    FestivalThemePack(
      name: 'Navratri Glow',
      primary: Color(0xFFD32F2F),
      accent: Color(0xFFFFC857),
      lightBackground: Color(0xFFFFF4F2),
      darkBackground: Color(0xFF170706),
      surfaceTint: Color(0xFFFFE7E1),
      heroGradient: <Color>[
        Color(0xFFD32F2F),
        Color(0xFFFF914D),
        Color(0xFFFFC857),
      ],
    ),
    FestivalThemePack(
      name: 'Sufi Night',
      primary: Color(0xFF2B5B6F),
      accent: Color(0xFFB8A46C),
      lightBackground: Color(0xFFF7F5EF),
      darkBackground: Color(0xFF071118),
      surfaceTint: Color(0xFFE9E3D2),
      heroGradient: <Color>[
        Color(0xFF0D2633),
        Color(0xFF2B5B6F),
        Color(0xFFB8A46C),
      ],
    ),
    FestivalThemePack(
      name: 'Pongal Harvest',
      primary: Color(0xFF9C5A12),
      accent: Color(0xFFFFBE5C),
      lightBackground: Color(0xFFFFF6E8),
      darkBackground: Color(0xFF130B04),
      surfaceTint: Color(0xFFFFE4BE),
      heroGradient: <Color>[
        Color(0xFF9C5A12),
        Color(0xFFDA8F1C),
        Color(0xFFFFBE5C),
      ],
    ),
    FestivalThemePack(
      name: 'Holi Bloom',
      primary: Color(0xFFE44B8D),
      accent: Color(0xFFFFC857),
      lightBackground: Color(0xFFFFF4FA),
      darkBackground: Color(0xFF170812),
      surfaceTint: Color(0xFFFFD8E9),
      heroGradient: <Color>[
        Color(0xFFE44B8D),
        Color(0xFF834DFF),
        Color(0xFFFFC857),
      ],
    ),
    FestivalThemePack(
      name: 'Winter Mehfil',
      primary: Color(0xFF4A4E69),
      accent: Color(0xFFE7C98A),
      lightBackground: Color(0xFFF8F7FB),
      darkBackground: Color(0xFF0D0F17),
      surfaceTint: Color(0xFFE6E4F0),
      heroGradient: <Color>[
        Color(0xFF22253B),
        Color(0xFF4A4E69),
        Color(0xFFE7C98A),
      ],
    ),
  ];

  static int autoPackIndexForDate(DateTime date) {
    if (date.month == 3) {
      return 6;
    }
    if (date.month == 7 || date.month == 8) {
      return 2;
    }
    if (date.month == 10 || date.month == 11) {
      return 1;
    }
    if (date.month == 1) {
      return 5;
    }
    if (date.month == 12) {
      return 7;
    }
    return 0;
  }

  static ThemeData build({
    required FestivalThemePack themePack,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: themePack.primary,
        onPrimary: Colors.white,
        secondary: themePack.accent,
        onSecondary: Colors.black,
        error: const Color(0xFFD62828),
        onError: Colors.white,
        surface: isDark ? const Color(0xFF18120D) : Colors.white,
        onSurface: isDark ? const Color(0xFFFFF4EA) : const Color(0xFF1C1209),
        primaryContainer: themePack.surfaceTint,
        onPrimaryContainer: const Color(0xFF2A1304),
        secondaryContainer: themePack.accent.withValues(alpha: 0.18),
        onSecondaryContainer: const Color(0xFF2A1304),
        surfaceContainerHighest:
            isDark ? const Color(0xFF241C16) : const Color(0xFFFFF1E3),
        onSurfaceVariant:
            isDark ? const Color(0xFFF0D9C8) : const Color(0xFF5B4637),
        outline: isDark ? const Color(0xFF5F4B3C) : const Color(0xFFE3C9B4),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: isDark ? Colors.white : const Color(0xFF1C1209),
        onInverseSurface: isDark ? const Color(0xFF1C1209) : Colors.white,
        inversePrimary: themePack.accent,
      ),
      scaffoldBackgroundColor:
          isDark ? themePack.darkBackground : themePack.lightBackground,
      cardColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.72),
    );

    final textTheme = GoogleFonts.hindTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.hind(
        fontSize: 17,
        height: 1.4,
        color: base.colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.hind(
        fontSize: 15.5,
        height: 1.4,
        color: base.colorScheme.onSurfaceVariant,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: base.colorScheme.onSurface,
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: base.colorScheme.surface.withValues(alpha: 0.66),
        side: BorderSide(color: base.colorScheme.outline),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: base.colorScheme.outline.withValues(alpha: 0.55),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: themePack.primary,
        inactiveTrackColor: themePack.accent.withValues(alpha: 0.25),
        thumbColor: themePack.accent,
        overlayColor: themePack.accent.withValues(alpha: 0.18),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF25190F) : const Color(0xFF2E1B09),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surface.withValues(
          alpha: isDark ? 0.12 : 0.84,
        ),
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: base.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: base.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: themePack.primary, width: 1.4),
        ),
      ),
    );
  }
}
