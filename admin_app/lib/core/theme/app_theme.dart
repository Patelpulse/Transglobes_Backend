import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF135BEC);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color backgroundColorDark = Color(0xFF101622);
  static const Color backgroundColorLight = Color(0xFFF6F6F8);

  static const Color surfaceColorDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF2D364A);

  static const Color textPrimaryLight = Color(0xFFF1F5F9);
  static const Color textSecondaryLight = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFF64748B);

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
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Color(0xFF1E293B),
        error: danger,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Manrope',
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }
}
