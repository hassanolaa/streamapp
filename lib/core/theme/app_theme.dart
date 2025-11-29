

import 'package:flutter/material.dart';

class AppTheme {
 // Private constructor to prevent instantiation
  AppTheme._();

  // --- LIGHT THEME ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xff319291),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xff319291),
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xff319291),
      onPrimary: Colors.white,
      secondary: Color(0xff4dc9a4),
      background: Color(0xFFFFFFFF),
      surface: Color(0xfff3f4f6), // Used for cards, dialogs, etc.
      onSurface: Color(0xff1b5a80), // Main text color
      error: Color(0xffd42032),
    ),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212), // A standard dark background
    primaryColor: const Color(0xff4dc9a4), // A brighter primary for dark mode
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xff4dc9a4),
      onPrimary: Colors.black,
      secondary: Color(0xff319291),
      background: Color(0xFF121212),
      surface: Color(0xFF1F1F1F), // Used for cards, dialogs, etc.
      onSurface: Color(0xFFFFFFFF), // Main text color
      error: Color(0xffd42032),
    ),
  );
}