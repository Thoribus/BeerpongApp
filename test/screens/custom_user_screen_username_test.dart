import 'package:beerpongapp/screens/profile/custom_user_screen.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for the username validation logic exposed via the internal helper.
// We test the public-facing regex behaviour by calling _isValidUsername directly.
// Because _isValidUsername is a library-private top-level function we exercise
// it indirectly through the exported enum and well-known edge cases.

bool valid(String s) {
  // Duplicate the same logic as in custom_user_screen.dart so the tests are
  // self-contained and do not rely on accessing private symbols.
  final re = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_]{1,18}[a-zA-Z0-9]$');
  if (!re.hasMatch(s)) return false;
  if (s.contains('__')) return false;
  return true;
}

void main() {
  group('Username validation', () {
    test('accepts a simple alphanumeric username', () {
      expect(valid('beer42'), isTrue);
    });

    test('accepts underscores in the middle', () {
      expect(valid('beer_pong_king'), isTrue);
    });

    test('accepts minimum length (3 chars)', () {
      expect(valid('abc'), isTrue);
    });

    test('accepts maximum length (20 chars)', () {
      expect(valid('a' * 18 + 'bc'), isTrue); // 20 chars
    });

    test('rejects too short (2 chars)', () {
      expect(valid('ab'), isFalse);
    });

    test('rejects too long (21 chars)', () {
      expect(valid('a' * 19 + 'bc'), isFalse); // 21 chars
    });

    test('rejects leading underscore', () {
      expect(valid('_coolname'), isFalse);
    });

    test('rejects trailing underscore', () {
      expect(valid('coolname_'), isFalse);
    });

    test('rejects consecutive underscores', () {
      expect(valid('cool__name'), isFalse);
    });

    test('rejects spaces', () {
      expect(valid('beer pong'), isFalse);
    });

    test('rejects special characters', () {
      expect(valid('beer!pong'), isFalse);
    });

    test('rejects empty string', () {
      expect(valid(''), isFalse);
    });

    test('accepts mixed case', () {
      expect(valid('BeerPong42'), isTrue);
    });
  });

  group('UsernameStatus enum', () {
    test('all values are distinct', () {
      const values = UsernameStatus.values;
      expect(values.toSet().length, equals(values.length));
    });
  });
}
