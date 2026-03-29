import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

void main() {
  group('Team toJson / fromJson', () {
    test('round-trip preserves color, isRearranged, wins, losses', () {
      final team = Team(
        color: Colors.blue,
        players: [],
        cups: [],
        isRearranged: true,
        canIslandShot: false,
        wins: 3,
        losses: 1,
      );

      final json = team.toJson();
      final restored = Team.fromJson(json);

      // After serialization Color(int) returns a plain Color, not MaterialColor.
      // Compare via ARGB integer to avoid type mismatch.
      expect(restored.color.toARGB32(), Colors.blue.toARGB32());
      expect(restored.isRearranged, isTrue);
      expect(restored.canIslandShot, isFalse);
      expect(restored.wins, 3);
      expect(restored.losses, 1);
    });

    test('colorValue field persists through serialization', () {
      const originalColor = Colors.red;
      final team = Team(color: originalColor, players: [], cups: []);

      final json = team.toJson();

      expect(json.containsKey('colorValue'), isTrue);
      expect(json['colorValue'], originalColor.toARGB32());

      final restored = Team.fromJson(json);
      expect(restored.color.toARGB32(), originalColor.toARGB32());
    });

    test('fromJson with empty players list produces empty list', () {
      final json = <String, dynamic>{
        'colorValue': Colors.green.toARGB32(),
        'players': [],
        'cups': [],
        'isRearranged': false,
        'canIslandShot': true,
        'wins': 0,
        'losses': 0,
      };

      final team = Team.fromJson(json);

      expect(team.players, isEmpty);
    });

    test('round-trip preserves players', () {
      final player = Player(name: 'Alice', score: 5.0, throws: 10, misses: 2, airballs: 1);
      final team = Team(
        color: Colors.blue,
        players: [player],
        cups: [],
      );

      final restored = Team.fromJson(team.toJson());

      expect(restored.players.length, 1);
      expect(restored.players.first.name, 'Alice');
      expect(restored.players.first.score, 5.0);
    });

    test('round-trip preserves cups', () {
      final cups = [
        Cup(index: 0, color: Colors.blue),
        Cup(index: 1, color: Colors.blue),
      ];
      final team = Team(color: Colors.blue, players: [], cups: cups);

      final restored = Team.fromJson(team.toJson());

      expect(restored.cups.length, 2);
      expect(restored.cups[0].index, 0);
      expect(restored.cups[1].index, 1);
    });

    test('fromJson uses defaults when optional fields are absent', () {
      final json = <String, dynamic>{
        'colorValue': Colors.blue.toARGB32(),
        'players': null,
        'cups': null,
      };

      final team = Team.fromJson(json);

      expect(team.players, isEmpty);
      expect(team.cups, isEmpty);
      expect(team.isRearranged, isFalse);
      expect(team.canIslandShot, isTrue);
      expect(team.wins, 0);
      expect(team.losses, 0);
    });

    test('clone produces independent copy', () {
      final team = Team(
        color: Colors.red,
        players: [Player(name: 'Bob')],
        cups: [Cup(index: 0)],
        wins: 2,
      );

      final clone = team.clone();
      clone.players.add(Player(name: 'Extra'));

      expect(team.players.length, 1);
      expect(clone.players.length, 2);
    });
  });
}
