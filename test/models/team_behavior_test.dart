import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

Team _makeTeam({int playerCount = 2, int cupCount = 10}) {
  return Team(
    color: Colors.blue,
    players: List.generate(playerCount, (i) => Player(name: 'P${i + 1}')),
    cups: List.generate(cupCount, (i) => Cup(index: i, color: Colors.blue)),
  );
}

void main() {
  group('Team.rotatePlayers', () {
    test('1-player team returns same player unchanged', () {
      final team = _makeTeam(playerCount: 1);
      final result = team.rotatePlayers();
      expect(result.length, 1);
      expect(result.first.name, 'P1');
    });

    test('2-player team returns both players unchanged', () {
      final team = _makeTeam(playerCount: 2);
      final result = team.rotatePlayers();
      expect(result.length, 2);
      expect(result.map((p) => p.name), containsAll(['P1', 'P2']));
    });

    test('3-player team rotates first two to end and returns first two of remaining', () {
      final team = _makeTeam(playerCount: 4);
      final initialFirst = team.players[0].name;
      final initialSecond = team.players[1].name;

      final result = team.rotatePlayers();

      // P1 and P2 moved to end; result is now P3, P4
      expect(result.length, 2);
      expect(result[0].name, 'P3');
      expect(result[1].name, 'P4');
      // Original list now ends with P1, P2
      expect(team.players.last.name, initialSecond);
      expect(team.players[team.players.length - 2].name, initialFirst);
    });

    test('currentPlayers is updated after rotation', () {
      final team = _makeTeam(playerCount: 4);
      team.rotatePlayers();
      expect(team.currentPlayers.length, 2);
    });
  });

  group('Team.ballsBack', () {
    test('returns true when all current players each hit once', () {
      final team = _makeTeam(playerCount: 2);
      team.currentPlayers = team.players;
      for (final p in team.currentPlayers) {
        p.hitThisRound = 1;
      }
      expect(team.ballsBack(), isTrue);
    });

    test('returns false when only one of two players hit', () {
      final team = _makeTeam(playerCount: 2);
      team.currentPlayers = team.players;
      team.currentPlayers[0].hitThisRound = 1;
      team.currentPlayers[1].hitThisRound = 0;
      expect(team.ballsBack(), isFalse);
    });

    test('returns false when no players hit', () {
      final team = _makeTeam(playerCount: 2);
      team.currentPlayers = team.players;
      expect(team.ballsBack(), isFalse);
    });

    test('returns true for a single-player team that hit twice', () {
      // ballsBack checks sum == 2; a solo player needs hitThisRound = 2.
      final team = _makeTeam(playerCount: 1);
      team.currentPlayers = team.players;
      team.currentPlayers[0].hitThisRound = 2;
      expect(team.ballsBack(), isTrue);
    });

    test('returns false for empty currentPlayers', () {
      final team = _makeTeam(playerCount: 2);
      team.currentPlayers = [];
      expect(team.ballsBack(), isFalse);
    });
  });

  group('Team.copyWith', () {
    test('unchanged fields are preserved', () {
      final team = _makeTeam();
      team.wins = 3;
      team.losses = 1;

      final copy = team.copyWith();
      expect(copy.wins, 3);
      expect(copy.losses, 1);
      expect(copy.color.toARGB32(), Colors.blue.toARGB32());
    });

    test('overriding wins does not affect losses', () {
      final team = _makeTeam();
      team.wins = 3;
      team.losses = 1;

      final copy = team.copyWith(wins: 10);
      expect(copy.wins, 10);
      expect(copy.losses, 1);
    });

    test('overriding color works', () {
      final team = _makeTeam();
      final copy = team.copyWith(color: Colors.red);
      expect(copy.color.toARGB32(), Colors.red.toARGB32());
    });

    test('overriding canIslandShot works', () {
      final team = _makeTeam();
      expect(team.canIslandShot, isTrue);
      final copy = team.copyWith(canIslandShot: false);
      expect(copy.canIslandShot, isFalse);
    });

    test('overriding isRearranged works', () {
      final team = _makeTeam();
      final copy = team.copyWith(isRearranged: true);
      expect(copy.isRearranged, isTrue);
    });
  });

  group('Team.toString', () {
    test('includes color and players', () {
      final team = _makeTeam(playerCount: 1);
      final str = team.toString();
      expect(str, contains('Team('));
      expect(str, contains('players'));
    });
  });
}
