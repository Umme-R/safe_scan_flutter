import 'package:flutter/material.dart';

class SafeScanTheme {
  static const Color primary = Color(0xFFDDA0DD); // Plum
  static const Color primaryVariant = Color(0xFFC3B1E1); // Custom lavender
  static const Color secondary = Color(0xFF9370DB); // Medium purple
  static const Color background = Color(0xFFF8F8FF); // Ghost white
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color error = Color(0xFFF44336); // Red
  static const Color safeGreen = Color(0xFF4CAF50); // Green
  static const Color onPrimary = Color(
    0xFF4B0082,
  ); // Indigo for text on primary
  static const Color onBackground = Color(
    0xFF2C1810,
  ); // Dark brown for contrast

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ).copyWith(secondary: secondary, surfaceVariant: primaryVariant),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shadowColor: Colors.black26,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onBackground,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: onBackground),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: onBackground.withOpacity(0.8),
        ),
      ),
    );
  }
}
