import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';

User _base() => User(id: 'u1', username: 'Tester');

void main() {
  group('User — stars field', () {
    test('defaults to 0', () {
      expect(_base().stars, 0);
    });

    test('toJson includes stars', () {
      final u = User(id: 'u1', username: 'Tester', stars: 150);
      expect(u.toJson()['stars'], 150);
    });

    test('fromJson reads stars', () {
      final u = User.fromJson({
        'id': 'u1',
        'username': 'Tester',
        'stars': 250,
      });
      expect(u.stars, 250);
    });

    test('fromJson defaults stars to 0 when absent', () {
      final u = User.fromJson({'id': 'u1', 'username': 'Tester'});
      expect(u.stars, 0);
    });

    test('copyWith updates stars', () {
      final u = _base().copyWith(stars: 500);
      expect(u.stars, 500);
    });

    test('copyWith preserves stars when not specified', () {
      final u = User(id: 'u1', username: 'Tester', stars: 99);
      expect(u.copyWith(username: 'Other').stars, 99);
    });
  });

  group('User — purchasedItems field', () {
    test('defaults to empty list', () {
      expect(_base().purchasedItems, isEmpty);
    });

    test('toJson includes purchasedItems', () {
      final u = User(
          id: 'u1', username: 'Tester', purchasedItems: ['avatar_catbeer']);
      expect(u.toJson()['purchasedItems'], ['avatar_catbeer']);
    });

    test('fromJson reads purchasedItems', () {
      final u = User.fromJson({
        'id': 'u1',
        'username': 'Tester',
        'purchasedItems': ['bg_blue', 'avatar_catbeer'],
      });
      expect(u.purchasedItems, ['bg_blue', 'avatar_catbeer']);
    });

    test('fromJson defaults purchasedItems to empty when absent', () {
      final u = User.fromJson({'id': 'u1', 'username': 'Tester'});
      expect(u.purchasedItems, isEmpty);
    });

    test('copyWith updates purchasedItems', () {
      final u = _base().copyWith(purchasedItems: ['title_king']);
      expect(u.purchasedItems, ['title_king']);
    });

    test('copyWith preserves purchasedItems when not specified', () {
      final u =
          User(id: 'u1', username: 'Tester', purchasedItems: ['bg_purple']);
      expect(u.copyWith(username: 'Other').purchasedItems, ['bg_purple']);
    });
  });
}
