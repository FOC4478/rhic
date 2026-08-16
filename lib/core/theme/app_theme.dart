import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF3A064D);
  static const Color darkPurple = Color(0xFF280035);
  static const Color background = Color(0xFFFFFEFB);
  static const Color textDark = Color(0xFF252525);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
    ),

    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: textDark,
    ),
  );
}