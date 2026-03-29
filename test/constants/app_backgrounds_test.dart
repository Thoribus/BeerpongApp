import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/constants.dart';

void main() {
  group('AppConstants — backgroundKeys', () {
    test('contains exactly 6 entries', () {
      expect(AppConstants.backgroundKeys.length, 6);
    });

    test('bg_default is the first entry', () {
      expect(AppConstants.backgroundKeys.first, 'bg_default');
    });

    test('includes all expected keys', () {
      const expected = [
        'bg_default', 'bg_amber', 'bg_blue', 'bg_green', 'bg_purple', 'bg_dark',
      ];
      expect(AppConstants.backgroundKeys, equals(expected));
    });

    test('backgroundLevelRequirements has an entry for every key', () {
      for (final key in AppConstants.backgroundKeys) {
        expect(
          AppConstants.backgroundLevelRequirements.containsKey(key),
          isTrue,
          reason: '$key missing from backgroundLevelRequirements',
        );
      }
    });

    test('bg_default and bg_amber are unlocked at level 1', () {
      expect(AppConstants.backgroundLevelRequirements['bg_default'], 1);
      expect(AppConstants.backgroundLevelRequirements['bg_amber'], 1);
    });

    test('level requirements are non-decreasing', () {
      final levels = AppConstants.backgroundKeys
          .map((k) => AppConstants.backgroundLevelRequirements[k]!)
          .toList();
      for (int i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThanOrEqualTo(levels[i - 1]),
            reason: 'Level requirement dropped between index ${i-1} and $i');
      }
    });
  });

  group('AppBackgrounds — gradientFor', () {
    test('returns a LinearGradient for every background key', () {
      for (final key in AppConstants.backgroundKeys) {
        final g = AppBackgrounds.gradientFor(key);
        expect(g, isA<LinearGradient>(),
            reason: '$key should return a LinearGradient');
        expect(g.colors.length, greaterThanOrEqualTo(2),
            reason: '$key gradient must have at least 2 colors');
      }
    });

    test('bg_amber gradient contains amber/brown tones', () {
      final g = AppBackgrounds.gradientFor('bg_amber');
      // The first color should have a red channel > green channel (warm amber)
      final color = g.colors.first;
      final r = (color.r * 255.0).round();
      final gr = (color.g * 255.0).round();
      expect(r, greaterThan(gr));
    });

    test('bg_blue gradient first color has dominant blue channel', () {
      final g = AppBackgrounds.gradientFor('bg_blue');
      final color = g.colors.first;
      final b = (color.b * 255.0).round();
      final r = (color.r * 255.0).round();
      expect(b, greaterThan(r));
    });

    test('bg_green gradient first color has dominant green channel', () {
      final g = AppBackgrounds.gradientFor('bg_green');
      final color = g.colors.first;
      final gr = (color.g * 255.0).round();
      final r = (color.r * 255.0).round();
      expect(gr, greaterThan(r));
    });

    test('unknown key falls back to default gradient', () {
      final g = AppBackgrounds.gradientFor('bg_nonexistent');
      expect(g, isA<LinearGradient>());
    });

    test('all gradients have topLeft→bottomRight direction', () {
      for (final key in AppConstants.backgroundKeys) {
        final g = AppBackgrounds.gradientFor(key);
        expect(g.begin, equals(Alignment.topLeft));
        expect(g.end, equals(Alignment.bottomRight));
      }
    });
  });

  group('AppBackgrounds — labelFor', () {
    test('returns correct label for each key', () {
      expect(AppBackgrounds.labelFor('bg_default'), 'Default');
      expect(AppBackgrounds.labelFor('bg_amber'),   'Amber');
      expect(AppBackgrounds.labelFor('bg_blue'),    'Blue');
      expect(AppBackgrounds.labelFor('bg_green'),   'Green');
      expect(AppBackgrounds.labelFor('bg_purple'),  'Purple');
      expect(AppBackgrounds.labelFor('bg_dark'),    'Dark');
    });

    test('unknown key returns Default', () {
      expect(AppBackgrounds.labelFor('bg_whatever'), 'Default');
    });
  });
}
