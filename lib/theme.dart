import 'package:flutter/material.dart';

/// Semantic colour resolver — call `AppColors.of(context)` once per build
/// and use the returned object throughout that widget's build method.
class AppColors {
  final bool isDark;
  const AppColors._(this.isDark);

  static AppColors of(BuildContext context) =>
      AppColors._(Theme.of(context).brightness == Brightness.dark);

  // ── Backgrounds ──────────────────────────────────────────────────────────
  Color get background  => isDark ? AppTheme.backgroundDark    : const Color(0xFFF5F5F5);
  Color get surface     => isDark ? AppTheme.surfaceDark        : Colors.white;
  Color get surface2    => isDark ? AppTheme.surfaceDark2       : const Color(0xFFF0F0F0);
  Color get appBar      => isDark ? AppTheme.tabBarBackground   : AppTheme.navBarLight;
  Color get navBar      => isDark ? AppTheme.navBarDark         : AppTheme.navBarLight;
  Color get drawerHeader => isDark ? AppTheme.surfaceDark2      : AppTheme.navBarLight;

  // ── Text ─────────────────────────────────────────────────────────────────
  Color get onBackground => isDark ? Colors.white              : const Color(0xFF1A1A1A);
  Color get subtle       => isDark ? const Color(0xFFBDBDBD)   : Colors.grey.shade600;
  Color get muted        => isDark ? Colors.white38            : Colors.black38;

  // ── Structure ─────────────────────────────────────────────────────────────
  Color get border  => isDark ? AppTheme.surfaceDark2   : const Color(0xFFE0E0E0);
  Color get divider => isDark ? Colors.white12          : Colors.black12;
  Color get card    => isDark ? AppTheme.surfaceDark    : Colors.white;
  Color get chip    => isDark ? AppTheme.surfaceDark2   : const Color(0xFFEDEDED);
}

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
  // Tab bar defaults
  static const Color tabBarBackground = Color(0xFF424242); // grey.shade800
  static const Color tabBarInactive = Color(0xFF757575);   // grey.shade600

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
