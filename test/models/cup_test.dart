import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/cup.dart';

void main() {
  test('Cup toJson and fromJson', () {
    final cup = Cup(index: 1, color: Colors.blue);
    final json = cup.toJson();
    final newCup = Cup.fromJson(json);

    expect(newCup.index, cup.index);
    expect(newCup.isVisible, cup.isVisible);
    expect(newCup.color, cup.color);
  });

  test('Cup clone', () {
    final cup = Cup(index: 1, color: Colors.red);
    final clone = cup.clone();

    expect(clone.index, cup.index);
    expect(clone.isVisible, cup.isVisible);
    expect(clone.color, cup.color);
  });

  test('Cup encodeList and decodeList', () {
    final cups = [
      Cup(index: 1, color: Colors.red),
      Cup(index: 2, color: Colors.blue),
    ];
    final jsonString = Cup.encodeList(cups);
    final decodedCups = Cup.decodeList(jsonString);

    expect(decodedCups.length, cups.length);
    expect(decodedCups[0].index, cups[0].index);
    expect(decodedCups[1].index, cups[1].index);
  });
}
