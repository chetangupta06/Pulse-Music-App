import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getTheme(String mode) {
    final isSlate = mode == 'black';
    final isMidnight = mode == 'midnight';
    final isDark = isSlate || isMidnight;
    
    // JioSaavn styled colors
    final primary = const Color(0xFF2BC5B4); // Signature Teal/Green
    
    // Light: Floral White (#FFFAF0) for main background, Almond (#F2E8DA) for surfaces. 
    // Slate: Navy/Slate (#26263A) for main background, slightly lighter (#32324A) for surfaces.
    // Midnight: Pitch black (#0F0F0F) for main background, dark gray (#18181A) for surfaces.
    final scaffoldBg = isSlate ? const Color(0xFF26263A) : (isMidnight ? const Color(0xFF0F0F0F) : const Color(0xFFFFFAF0));
    final surface = isSlate ? const Color(0xFF32324A) : (isMidnight ? const Color(0xFF18181A) : const Color(0xFFF2E8DA));
    
    final textColor = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF71717A);
    final dividerColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.08);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: const Color(0xFF4C4C4C), // Dark secondary for icons in light mode
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: surface,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ).copyWith(
        bodySmall: GoogleFonts.inter(color: subtitleColor),
        labelSmall: GoogleFonts.inter(color: subtitleColor),
      ),
      dividerColor: dividerColor,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.inter(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
    );
  }

  static Color primary(String mode) => const Color(0xFF2BC5B4);
  static Color background(String mode) => (mode == 'black') ? const Color(0xFF26263A) : ((mode == 'midnight') ? const Color(0xFF0F0F0F) : const Color(0xFFFFFAF0));
  static Color surface(String mode) => (mode == 'black') ? const Color(0xFF32324A) : ((mode == 'midnight') ? const Color(0xFF18181A) : const Color(0xFFF2E8DA));
}
