import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color green = Color(0xFF176B45);
  static const Color darkGreen = Color(0xFF0F5132);

  static const Color greenLight = Color(0xFF23845A);
  static const Color greenSoft = Color(0xFF2D8A63);

  static const Color gold = Color(0xFFC9A45C);
  static const Color goldLight = Color(0xFFE4C987);
  static const Color goldSoft = Color(0xFFB99550);

  static const Color lightBackground = Color(0xFFF7F4EA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF06130F);
  static const Color darkSurface = Color(0xFF081A13);
  static const Color darkCard = Color(0xFF0D251C);
  static const Color darkCard2 = Color(0xFF123225);

  static const Color lightText = Color(0xFF17231D);
  static const Color darkText = Color(0xFFF2EBDD);

  static const Color secondaryTextLight = Color(0xFF68736D);
  static const Color secondaryTextDark = Color(0xFFB8C5BE);

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
    ).copyWith(
      primary: darkGreen,
      secondary: gold,
      surface: lightSurface,
      onSurface: lightText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: lightBackground,

      fontFamily: 'sans',

      appBarTheme: const AppBarTheme(
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E0D5),
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: darkGreen,
        size: 24,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: darkGreen,
        textColor: lightText,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE2DED3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color(0xFFE2DED3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: darkGreen,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          color: secondaryTextLight,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF8A938D),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
         
