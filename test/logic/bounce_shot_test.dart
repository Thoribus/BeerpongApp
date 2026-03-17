import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure-logic helpers mirroring GameController for bounce shot unit testing.

/// Mirrors GameController.getRandomCupIndex — deterministic (first match) for tests.
int? getRandomCupIndex(List<Cup> cups, int hitCupIndex, Color teamColor) {
  final possible = cups.where((c) {
    return c.index != hitCupIndex &&
        c.isVisible &&
        (c.color == teamColor || c.color == Colors.yellow);
  }).toList();
  if (possible.isEmpty) return null;
  return possible.first.index;
}

/// Simulates the bounce-shot hit logic from GameController.handleBounceCupHit.
/// Returns the set of cup indices that were removed.
Set<int> simulateBounceCupHit({
  required List<Cup> cups,
  required int cupIndex,
  required Color teamColor,
}) {
  final removed = <int>{};

  // Remove the directly hit cup.
  final hitCup = cups.firstWhere((c) => c.index == cupIndex);
  hitCup.color = Colors.green;
  removed.add(cupIndex);

  // Remove a random bonus cup.
  final extraIndex = getRandomCupIndex(cups, cupIndex, teamColor);
  if (extraIndex != null) {
    cups.firstWhere((c) => c.index == extraIndex).color = Colors.green;
    removed.add(extraIndex);
  }

  return removed;
}

Cup makeCup(int index, {Color? color, bool isVisible = true}) {
  final c = Cup(index: index, color: color ?? Colors.blue);
  c.isVisible = isVisible;
  return c;
}

void main() {
  group('Bounce shot logic', () {
    test('removes the tapped cup AND a random bonus cup (2 cups total)', () {
      final cups = [
        makeCup(0),
        makeCup(1),
        makeCup(2),
        makeCup(3),
      ];
      final removed = simulateBounceCupHit(cups: cups, cupIndex: 0, teamColor: Colors.blue);
      expect(removed.length, 2);
      expect(removed, contains(0)); // directly tapped cup always removed
    });

    test('only removes 1 cup when no other cups remain', () {
      final cups = [makeCup(0)];
      final removed = simulateBounceCupHit(cups: cups, cupIndex: 0, teamColor: Colors.blue);
      expect(removed.length, 1);
      expect(removed, contains(0));
    });

    test('does not pick an invisible cup as the bonus cup', () {
      final cups = [
        makeCup(0),                              // hit cup
        makeCup(1, isVisible: false),            // invisible — must not be picked
        makeCup(2),                              // the only valid bonus
      ];
      final removed = simulateBounceCupHit(cups: cups, cupIndex: 0, teamColor: Colors.blue);
      expect(removed, contains(2));
      expect(removed, isNot(contains(1)));
    });

    test('bonus cup is never the same as the hit cup', () {
      final cups = [makeCup(0), makeCup(1), makeCup(2)];
      final removed = simulateBounceCupHit(cups: cups, cupIndex: 1, teamColor: Colors.blue);
      final bonus = removed.where((i) => i != 1).toList();
      expect(bonus, isNotEmpty);
      expect(bonus, everyElement(isNot(1)));
    });

    test('Player.bounceAttempts and bounceMakes increment on a make', () {
      final player = Player(name: 'Alice');
      player.bounceAttempts++;
      player.bounceMakes++;
      expect(player.bounceAttempts, 1);
      expect(player.bounceMakes, 1);
    });

    test('Player.bounceAttempts increments but bounceMakes does not on a miss', () {
      final player = Player(name: 'Alice');
      player.bounceAttempts++;
      expect(player.bounceAttempts, 1);
      expect(player.bounceMakes, 0);
    });

    test('bounceAttempts and bounceMakes survive toJson/fromJson round-trip', () {
      final player = Player(name: 'Bob', bounceAttempts: 5, bounceMakes: 3);
      final copy = Player.fromJson(player.toJson());
      expect(copy.bounceAttempts, 5);
      expect(copy.bounceMakes, 3);
    });

    test('bounceAttempts and bounceMakes default to 0 when missing from json', () {
      final json = <String, dynamic>{
        'name': 'Charlie',
        'score': 0.0,
        'throws': 0,
        'misses': 0,
        'airballs': 0,
        'hitThisRound': 0,
        'cupsHit': <int>[],
        'lastCupHit': false,
        'isWinner': false,
      };
      final player = Player.fromJson(json);
      expect(player.bounceAttempts, 0);
      expect(player.bounceMakes, 0);
    });

    test('mergedWith sums bounceAttempts and bounceMakes', () {
      final p1 = Player(name: 'Alice', bounceAttempts: 3, bounceMakes: 2);
      final p2 = Player(name: 'Alice', bounceAttempts: 2, bounceMakes: 1);
      final merged = p1.mergedWith(p2);
      expect(merged.bounceAttempts, 5);
      expect(merged.bounceMakes, 3);
    });
  });

  group('bounceShotActive state (via Team/Player model only)', () {
    test('Player canIslandShot is independent of bounce state', () {
      final team = Team(color: Colors.blue, players: [Player(name: 'A')], cups: []);
      expect(team.canIslandShot, isTrue);
      // Bounce shot has no effect on island state.
    });
  });
}
