

import 'package:flutter/material.dart';


class AppTheme {
  AppTheme._();

  // TV Streaming App Color Palette
  static const Color _darkBg = Color(0xFF0B0E14);
  static const Color _darkSurface = Color(0xFF141922);
  static const Color _accentBlue = Color(0xFF5B6EF5);
  static const Color _accentPurple = Color(0xFF7B5FE8);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0B3B8);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    primaryColor: _accentBlue,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: _textPrimary),
    ),
    colorScheme: const ColorScheme.dark(
      primary: _accentBlue,
      secondary: _accentPurple,
      background: _darkBg,
      surface: _darkSurface,
      onPrimary: Colors.white,
      onSurface: _textPrimary,
      onBackground: _textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: _accentBlue,
    colorScheme: const ColorScheme.light(
      primary: _accentBlue,
      secondary: _accentPurple,
      background: Color(0xFFF5F5F5),
      surface: Colors.white,
    ),
  );
}
