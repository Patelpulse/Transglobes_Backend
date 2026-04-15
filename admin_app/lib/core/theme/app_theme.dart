import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF135BEC);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color backgroundColorDark = Color(0xFF0F172A);
  static const Color backgroundColorLight = Color(0xFFF6F7FB);

  // Screenshot-aligned admin palette
  static const Color pageBackground = Color(0xFFF6F6F4);
  static const Color cardBackground = Colors.white;
  static const Color sidebarBackground = Color(0xFFFBFBFA);
  static const Color topBarBackground = Color(0xFFFAFAF8);
  static const Color lineSoft = Color(0xFFE6E8EC);
  static const Color textPrimaryDark = Color(0xFF121826);
  static const Color textSecondaryDark = Color(0xFF5B6475);

  static const Color surfaceColorDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF2D364A);

  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFFE2E8F0);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColorDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColorDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
        error: danger,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColorDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: pageBackground,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardBackground,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
        error: danger,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: topBarBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
      ),
      dividerTheme: const DividerThemeData(color: lineSoft, thickness: 1),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBackground,
      ),
    );
  }
}
