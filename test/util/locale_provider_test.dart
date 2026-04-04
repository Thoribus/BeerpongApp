import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beerpongapp/util/locale_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider', () {
    test('defaults to English when no preference saved', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.locale.languageCode, 'en');
    });

    test('loads saved locale from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'locale_language_code': 'de'});
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(provider.locale.languageCode, 'de');
    });

    test('setLocale updates locale', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.setLocale(const Locale('de'));

      expect(provider.locale.languageCode, 'de');
    });

    test('setLocale persists to SharedPreferences', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.setLocale(const Locale('de'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale_language_code'), 'de');
    });

    test('setLocale with same locale does not notify listeners', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      // Same locale — should be a no-op
      await provider.setLocale(const Locale('en'));

      expect(notifyCount, 0);
    });

    test('setLocale with different locale notifies listeners', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setLocale(const Locale('de'));

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('can switch locale multiple times', () async {
      final provider = LocaleProvider();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await provider.setLocale(const Locale('de'));
      expect(provider.locale.languageCode, 'de');

      await provider.setLocale(const Locale('en'));
      expect(provider.locale.languageCode, 'en');
    });
  });
}
