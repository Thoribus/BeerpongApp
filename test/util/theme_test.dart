import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/theme.dart';

void main() {
  group('AppTheme constants', () {
    test('primary is amber', () {
      expect(AppTheme.primary, Colors.amber);
    });

    test('dark theme has dark brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('light theme has light brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('dark theme primary color is amber', () {
      expect(AppTheme.dark.primaryColor, Colors.amber);
    });

    test('light theme primary color is amber', () {
      expect(AppTheme.light.primaryColor, Colors.amber);
    });

    test('dark theme scaffold background matches backgroundDark', () {
      expect(AppTheme.dark.scaffoldBackgroundColor, AppTheme.backgroundDark);
    });

    test('all color constants are non-transparent', () {
      for (final color in [
        AppTheme.backgroundDark,
        AppTheme.surfaceDark,
        AppTheme.surfaceDark2,
        AppTheme.navBarDark,
        AppTheme.surfaceLight,
        AppTheme.navBarLight,
        AppTheme.tabBarBackground,
        AppTheme.tabBarInactive,
        AppTheme.gold,
      ]) {
        expect(color.a, greaterThan(0),
            reason: 'Expected non-transparent color, got $color');
      }
    });
  });

  group('AppColors — dark mode', () {
    testWidgets('AppColors.of returns dark colors in dark theme', (tester) async {
      late AppColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (ctx) {
              colors = AppColors.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(colors.isDark, isTrue);
      expect(colors.background, AppTheme.backgroundDark);
      expect(colors.surface, AppTheme.surfaceDark);
      expect(colors.surface2, AppTheme.surfaceDark2);
      expect(colors.navBar, AppTheme.navBarDark);
      expect(colors.card, AppTheme.surfaceDark);
      expect(colors.chip, AppTheme.surfaceDark2);
    });
  });

  group('AppColors — light mode', () {
    testWidgets('AppColors.of returns light colors in light theme', (tester) async {
      late AppColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (ctx) {
              colors = AppColors.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(colors.isDark, isFalse);
      expect(colors.background, const Color(0xFFF5F5F5));
      expect(colors.surface, Colors.white);
      expect(colors.card, Colors.white);
    });

    testWidgets('all color getters return a value in light mode', (tester) async {
      late AppColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (ctx) {
              colors = AppColors.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      // Verify every getter returns without throwing and is non-null
      expect(colors.background.a, greaterThan(0));
      expect(colors.surface2.a, greaterThan(0));
      expect(colors.appBar.a, greaterThan(0));
      expect(colors.drawerHeader.a, greaterThan(0));
      expect(colors.onBackground.a, greaterThan(0));
      expect(colors.subtle.a, greaterThan(0));
      expect(colors.border.a, greaterThan(0));
      expect(colors.divider.a, greaterThan(0));
    });
  });
}
