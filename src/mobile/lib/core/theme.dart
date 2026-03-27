import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0e1117);
  static const Color cardBackground = Color(0xFF1a1a2e);
  static const Color cardBorder = Color(0xFF2a2a3e);
  static const Color textPrimary = Color(0xFFfafafa);
  static const Color textSecondary = Color(0xFFa8a8b3);
  static const Color accentRed = Color(0xFFe94560);
  static const Color accentGreen = Color(0xFF2a9d8f);
  static const Color accentYellow = Color(0xFFe9c46a);
  static const Color accentBlue = Color(0xFF457b9d);
  static const Color accentOrange = Color(0xFFf4a261);
  static const Color accentCyan = Color(0xFF8ecae6);

  static const List<Color> chartColors = [
    accentRed,
    accentBlue,
    accentGreen,
    accentYellow,
    accentCyan,
    accentOrange,
    Color(0xFF264653),
    Color(0xFFa8dadc),
    Color(0xFFe76f51),
    Color(0xFF606c38),
  ];

  static const Map<String, Color> bankColors = {
    "BAC": Color(0xFFe63946),
    "BCR": Color(0xFF457b9d),
    "Promerica": Color(0xFF2a9d8f),
    "Multimoney": Color(0xFFe9c46a),
    "Efectivo": Color(0xFF8ecae6),
  };

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          secondary: accentBlue,
          surface: cardBackground,
          error: accentRed,
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: cardBorder, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0a0a12),
          indicatorColor: accentRed.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: accentRed, fontSize: 12);
            }
            return const TextStyle(color: textSecondary, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accentRed);
            }
            return const IconThemeData(color: textSecondary);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accentRed),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentRed,
            foregroundColor: textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentBlue,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardBackground,
          selectedColor: accentRed.withValues(alpha: 0.3),
          labelStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: cardBorder),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: cardBorder,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardBackground,
          contentTextStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}
