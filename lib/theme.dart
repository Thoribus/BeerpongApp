import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Colors.amber;
  static const Color gold = Color(0xFFF0AE1D);
  // Dark mode surfaces
  static const Color backgroundDark = Color(0xFF0E0F11);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDark2 = Color(0xFF2C2F36);
  static const Color navBarDark = Color(0xFF131417);
  // Light mode surfaces
  static const Color surfaceLight = Color(0xFFEDEDED);
  static const Color navBarLight = Color(0xFFDCDCDC);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          surface: surfaceDark,
        ),
        scaffoldBackgroundColor: backgroundDark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: surfaceDark,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? Colors.amber.shade700 : null,
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: primary,
        colorScheme: const ColorScheme.light(
          primary: primary,
          surface: Color(0xFFEDEDED),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFDCDCDC),
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFFEDEDED),
        ),
      );
}
