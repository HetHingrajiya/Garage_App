import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const primaryColor = Color(0xFF6366F1); // Modern Indigo
  static const secondaryColor = Color(0xFF1E293B); // Slate 800
  static const accentColor = Color(0xFF8B5CF6); // Violet
  static const surfaceColor = Color(0xFFF8FAFC); // Slate 50
  static const dashboardGradientStart = Color(0xFF6366F1);
  static const dashboardGradientEnd = Color(0xFF8B5CF6);

  // Status Colors
  static const successColor = Color(0xFF10B981); // Emerald
  static const warningColor = Color(0xFFF59E0B); // Amber
  static const errorColor = Color(0xFFEF4444); // Red

  // Neumorphic Colors - Light
  static const nmBaseLight = Color(0xFFF0F2F5); // Slightly lighter for better shadow depth
  static const nmLightShadowLight = Colors.white;
  static const nmDarkShadowLight = Color(0xFFD1D9E6); // More defined shadow

  // Neumorphic Colors - Dark
  static const nmBaseDark = Color(0xFF1E293B); // Slate 800 for better depth
  static const nmLightShadowDark = Color(0xFF334155); // Slate 700
  static const nmDarkShadowDark = Color(0xFF0F172A); // Slate 900

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: nmBaseLight,
      onSurface: const Color(0xFF2D3436),
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    scaffoldBackgroundColor: nmBaseLight,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: const Color(0xFF2D3436),
      displayColor: const Color(0xFF2D3436),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF2D3436),
      titleTextStyle: TextStyle(
        color: Color(0xFF2D3436),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: nmBaseLight,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: nmBaseLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF636E72)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: nmBaseLight,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: nmBaseDark,
      onSurface: const Color(0xFFE0E5EC),
      primary: primaryColor,
      secondary: const Color(0xFF64748B),
    ),
    scaffoldBackgroundColor: nmBaseDark,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFB2BEC3),
      displayColor: const Color(0xFFE0E5EC),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFE0E5EC),
      titleTextStyle: TextStyle(
        color: Color(0xFFE0E5EC),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: nmBaseDark,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: nmBaseDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFB2BEC3)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: nmBaseDark,
        foregroundColor: primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppTheme.primaryColor, AppTheme.accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surface = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glass = LinearGradient(
    colors: [
      Colors.white24,
      Colors.white12,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboard = LinearGradient(
    colors: [AppTheme.dashboardGradientStart, AppTheme.dashboardGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient success = LinearGradient(
    colors: [AppTheme.successColor, AppTheme.successColor.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient warning = LinearGradient(
    colors: [AppTheme.warningColor, AppTheme.warningColor.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient error = LinearGradient(
    colors: [AppTheme.errorColor, AppTheme.errorColor.withValues(alpha: 0.8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
