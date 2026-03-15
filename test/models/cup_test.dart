import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/cup.dart';

void main() {
  group('Cup', () {
    test('defaults to visible with red color', () {
      final cup = Cup(index: 0);
      expect(cup.isVisible, isTrue);
      expect(cup.color, Colors.red);
      expect(cup.index, 0);
    });

    test('constructor respects custom isVisible and color', () {
      final cup = Cup(index: 3, isVisible: false, color: Colors.blue);
      expect(cup.isVisible, isFalse);
      expect(cup.color, Colors.blue);
    });

    test('toJson / fromJson round-trip preserves index, visibility and color',
        () {
      const color = Color(0xFF4CAF50); // plain Color, not MaterialColor
      final cup = Cup(index: 5, isVisible: false, color: color);
      final json = cup.toJson();
      final restored = Cup.fromJson(json);

      expect(restored.index, 5);
      expect(restored.isVisible, isFalse);
      expect(restored.color.toARGB32(), color.toARGB32());
    });

    test('clone creates a new Cup with the same data but different key', () {
      const color = Color(0xFFFF9800); // plain Color
      final cup = Cup(index: 2, isVisible: false, color: color);
      final clone = cup.clone();

      expect(clone.index, 2);
      expect(clone.isVisible, isFalse);
      expect(clone.color.toARGB32(), color.toARGB32());
      expect(clone.key, isNot(equals(cup.key)));
    });

    test('each Cup gets a unique GlobalKey by default', () {
      final a = Cup(index: 0);
      final b = Cup(index: 1);
      expect(a.key, isNot(equals(b.key)));
    });

    test('toJson encodes color as integer', () {
      final cup = Cup(index: 0, color: Colors.red);
      final json = cup.toJson();
      expect(json['color'], isA<int>());
    });
  });
}
