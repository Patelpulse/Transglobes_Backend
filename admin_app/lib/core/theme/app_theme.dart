import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF135BEC);
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
        background: backgroundColorDark,
        surface: surfaceColorDark,
        onPrimary: Colors.white,
        onBackground: textPrimaryLight,
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColorDark,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
