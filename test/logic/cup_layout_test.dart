import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/game/cup_layout.dart';
import 'package:beerpongapp/models/cup.dart';

List<Cup> _makeCups(int n) =>
    List.generate(n, (i) => Cup(index: i, color: Colors.blue));

void main() {
  group('CupLayout.assignSpecificIndices', () {
    test('6 cups → indices [6,7,8,3,4,1]', () {
      final cups = _makeCups(6);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [6, 7, 8, 3, 4, 1]);
    });

    test('5 cups → indices [7,3,4,1,0]', () {
      final cups = _makeCups(5);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [7, 3, 4, 1, 0]);
    });

    test('4 cups → indices [7,3,4,1]', () {
      final cups = _makeCups(4);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [7, 3, 4, 1]);
    });

    test('3 cups → indices [7,8,4]', () {
      final cups = _makeCups(3);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [7, 8, 4]);
    });

    test('2 cups → indices [7,3]', () {
      final cups = _makeCups(2);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [7, 3]);
    });

    test('1 cup → indices [7]', () {
      final cups = _makeCups(1);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result.map((c) => c.index).toList(), [7]);
    });

    test('0 cups → indices unchanged (empty list)', () {
      final cups = _makeCups(0);
      final result = CupLayout.assignSpecificIndices(cups);
      expect(result, isEmpty);
    });

    test('all returned cups have isVisible = true', () {
      for (final n in [1, 2, 3, 4, 5, 6]) {
        final cups = _makeCups(n);
        final result = CupLayout.assignSpecificIndices(cups);
        expect(result.every((c) => c.isVisible), isTrue,
            reason: 'Expected all cups visible for n=$n');
      }
    });

    test('returned list length equals input length', () {
      for (final n in [0, 1, 2, 3, 4, 5, 6]) {
        final cups = _makeCups(n);
        final result = CupLayout.assignSpecificIndices(cups);
        expect(result.length, n);
      }
    });
  });
}
