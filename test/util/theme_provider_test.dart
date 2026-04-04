import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/util/theme_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('defaults to dark mode when no preference saved', () async {
      final provider = ThemeProvider();
      // Let _load() complete
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('loads saved dark=false preference', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': false});
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('loads saved dark=true preference', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': true});
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.isDarkMode, isTrue);
    });

    test('toggle switches from dark to light', () async {
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.isDarkMode, isTrue);

      await provider.toggle();

      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
    });

    test('toggle switches from light to dark', () async {
      SharedPreferences.setMockInitialValues({'isDarkMode': false});
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.toggle();

      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('toggle persists preference to SharedPreferences', () async {
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.toggle(); // dark → light

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isDarkMode'), isFalse);
    });

    test('notifies listeners on toggle', () async {
      final provider = ThemeProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggle();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}
