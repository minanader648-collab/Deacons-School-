import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Coptic Luxury Color Palette
  static const Color primaryBurgundy = Color(0xFF6B1D2F);
  static const Color primaryDarkBurgundy = Color(0xFF4A121F);
  static const Color copticGold = Color(0xFFD4AF37);
  static const Color copticAccentGold = Color(0xFFF3E5AB);
  static const Color copticNavy = Color(0xFF0F172A);
  static const Color cardDarkBackground = Color(0xFF1E293B);
  static const Color backgroundLight = Color(0xFFF8FAFCE6);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static ThemeData lightTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.cairoTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBurgundy,
      scaffoldBackgroundColor: const Color(0xFFF8FAF9),
      colorScheme: const ColorScheme.light(
        primary: primaryBurgundy,
        secondary: copticGold,
        surface: surfaceLight,
        background: Color(0xFFF8FAF9),
        onPrimary: Colors.white,
        onSecondary: primaryDarkBurgundy,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryBurgundy,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryDarkBurgundy,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF334155),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBurgundy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: copticAccentGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: primaryBurgundy.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: copticGold.withOpacity(0.2), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBurgundy,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBurgundy, width: 2),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBurgundy,
      scaffoldBackgroundColor: copticNavy,
      colorScheme: const ColorScheme.dark(
        primary: copticGold,
        secondary: primaryBurgundy,
        surface: cardDarkBackground,
        background: copticNavy,
        onPrimary: copticNavy,
        onSecondary: Colors.white,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: cardDarkBackground,
        foregroundColor: copticGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: copticGold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDarkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: copticGold.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }
}
