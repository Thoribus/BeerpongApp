import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure-logic helpers extracted from GameController for unit testing.
// We replicate the two functions under test so they can be exercised
// without a BuildContext or Firebase.

/// Mirrors GameController.toggleIslandCups — deactivation branch only.
/// Returns the cups list after deactivation.
List<Cup> deactivateIslandCups(List<Cup> cups, Color teamColor) {
  for (final cup in cups) {
    if (cup.color == Colors.yellow) cup.color = teamColor;
  }
  return cups;
}

/// Mirrors GameController.getRandomCupIndex.
int? getRandomCupIndex(List<Cup> cups, int hitCupIndex, Color teamColor) {
  final possible = cups.where((c) {
    return c.index != hitCupIndex &&
        c.isVisible &&
        (c.color == teamColor || c.color == Colors.yellow);
  }).toList();
  if (possible.isEmpty) return null;
  return possible.first.index; // deterministic for tests
}

Cup makeCup(int index, {Color? color, bool isVisible = true}) {
  final c = Cup(index: index, color: color ?? Colors.blue);
  c.isVisible = isVisible;
  return c;
}

void main() {
  group('toggleIslandCups deactivation', () {
    test('resets yellow cups to team color', () {
      final cups = [
        makeCup(0, color: Colors.blue),
        makeCup(1, color: Colors.yellow),
        makeCup(2, color: Colors.yellow),
      ];
      deactivateIslandCups(cups, Colors.blue);
      expect(cups[0].color, Colors.blue); // unchanged
      expect(cups[1].color, Colors.blue); // was yellow → reset
      expect(cups[2].color, Colors.blue); // was yellow → reset
    });

    test('does not touch green (already-hit) cups', () {
      final cups = [
        makeCup(0, color: Colors.green),
        makeCup(1, color: Colors.yellow),
      ];
      deactivateIslandCups(cups, Colors.blue);
      expect(cups[0].color, Colors.green); // green unchanged
      expect(cups[1].color, Colors.blue);  // yellow → team color
    });

    test('no-op when no yellow cups exist', () {
      final cups = [
        makeCup(0, color: Colors.blue),
        makeCup(1, color: Colors.green),
      ];
      deactivateIslandCups(cups, Colors.blue);
      expect(cups[0].color, Colors.blue);
      expect(cups[1].color, Colors.green);
    });
  });

  group('getRandomCupIndex', () {
    test('excludes the just-hit cup', () {
      final cups = [
        makeCup(0, color: Colors.blue),
        makeCup(1, color: Colors.blue),
      ];
      final idx = getRandomCupIndex(cups, 0, Colors.blue);
      expect(idx, 1);
    });

    test('includes yellow cups as valid bonus targets', () {
      final cups = [
        makeCup(0, color: Colors.yellow), // island — just hit
        makeCup(1, color: Colors.yellow), // another island cup
        makeCup(2, color: Colors.blue),
      ];
      // Hit cup 0; bonus should come from cup 1 or 2.
      final idx = getRandomCupIndex(cups, 0, Colors.blue);
      expect(idx, isNotNull);
      expect(idx, isNot(0));
    });

    test('excludes invisible cups', () {
      final cups = [
        makeCup(0, color: Colors.blue),
        makeCup(1, color: Colors.blue, isVisible: false),
        makeCup(2, color: Colors.blue),
      ];
      final idx = getRandomCupIndex(cups, 0, Colors.blue);
      expect(idx, isNot(1)); // invisible cup must not be picked
    });

    test('returns null when no valid bonus cups remain', () {
      final cups = [
        makeCup(0, color: Colors.yellow), // just hit, the only cup
      ];
      final idx = getRandomCupIndex(cups, 0, Colors.blue);
      expect(idx, isNull);
    });
  });

  group('Player.islandShotUsed tracking', () {
    test('starts as false', () {
      final player = Player(name: 'Alice');
      expect(player.islandShotUsed, isFalse);
    });

    test('persists through toJson/fromJson round-trip', () {
      final player = Player(name: 'Alice')..islandShotUsed = true;
      final copy = Player.fromJson(player.toJson());
      expect(copy.islandShotUsed, isTrue);
    });
  });

  group('Team.canIslandShot tracking', () {
    test('defaults to true', () {
      final team = Team(color: Colors.blue, players: [Player(name: 'A')], cups: []);
      expect(team.canIslandShot, isTrue);
    });

    test('persists through toJson/fromJson round-trip', () {
      final team = Team(color: Colors.blue, players: [Player(name: 'A')], cups: [])
        ..canIslandShot = false;
      final copy = Team.fromJson(team.toJson());
      expect(copy.canIslandShot, isFalse);
    });
  });
}
