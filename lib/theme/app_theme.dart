// lib/themes/app_theme.dart - Theme system implementation
import 'package:flutter/material.dart';

class AppTheme {
  // Color palette extracted from your images
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF388E3C);
  static const Color primaryGreenLight = Color(0xFF81C784);

  // Light theme colors (matching your beige/cream design)
  static const Color lightBackground = Color(0xFFF5F1E8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Dark theme colors (matching your dark design)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFBBBBBB);
  static const Color darkDivider = Color(0xFF333333);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: 'Digital',

    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: primaryGreenLight,
      background: lightBackground,
      surface: lightSurface,
      onBackground: lightText,
      onSurface: lightText,
      onPrimary: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      foregroundColor: lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Digital',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: lightText,
      ),
    ),

    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: lightDivider,
      thickness: 1,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightText, fontFamily: 'Digital'),
      bodyMedium: TextStyle(color: lightText, fontFamily: 'Digital'),
      titleLarge: TextStyle(color: lightText, fontFamily: 'Digital', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: lightText, fontFamily: 'Digital'),
      labelMedium: TextStyle(color: lightTextSecondary, fontFamily: 'Digital'),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Digital',

    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: primaryGreenLight,
      background: darkBackground,
      surface: darkSurface,
      onBackground: darkText,
      onSurface: darkText,
      onPrimary: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Digital',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: darkDivider,
      thickness: 1,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkText, fontFamily: 'Digital'),
      bodyMedium: TextStyle(color: darkText, fontFamily: 'Digital'),
      titleLarge: TextStyle(color: darkText, fontFamily: 'Digital', fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: darkText, fontFamily: 'Digital'),
      labelMedium: TextStyle(color: darkTextSecondary, fontFamily: 'Digital'),
    ),
  );
}