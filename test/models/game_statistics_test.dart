import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';

// Minimal valid player JSON matching Player.fromJson requirements.
Map<String, dynamic> _playerJson(String name) => {
      'name': name,
      'score': 3.0,
      'throws': 6,
      'misses': 2,
      'airballs': 1,
      'hitThisRound': 0,
      'cupsHit': [0, 1, 2],
      'lastCupHit': false,
      'islandShotUsed': false,
      'islandMakes': 0,
      'defended': 0,
      'consecutiveHits': 0,
      'onFire': 0,
      'heatingUp': 0,
      'bounceAttempts': 0,
      'bounceMakes': 0,
      'isWinner': false,
    };

Map<String, dynamic> _baseData({
  Timestamp? timestamp,
  Timestamp? endedAt,
  int? roundCount,
  int? cupsRemainingWinner,
  String? gameMode,
  List<String>? specialRules,
}) =>
    {
      'timestamp': timestamp,
      'endedAt': endedAt,
      'winner': 'Team 1',
      'team1': {
        'players': [_playerJson('Alice')],
      },
      'team2': {
        'players': [_playerJson('Bob')],
      },
      'participants': ['Alice', 'Bob'],
      if (roundCount != null) 'roundCount': roundCount,
      if (cupsRemainingWinner != null)
        'cupsRemainingWinner': cupsRemainingWinner,
      if (gameMode != null) 'gameMode': gameMode,
      if (specialRules != null) 'specialRules': specialRules,
    };

void main() {
  group('GameStatistics.fromFirestore — new fields', () {
    test('parses roundCount from Firestore data', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData(roundCount: 7));
      expect(gs.roundCount, 7);
    });

    test('defaults roundCount to 0 when absent', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData());
      expect(gs.roundCount, 0);
    });

    test('parses cupsRemainingWinner from Firestore data', () {
      final gs =
          GameStatistics.fromFirestore('g1', _baseData(cupsRemainingWinner: 4));
      expect(gs.cupsRemainingWinner, 4);
    });

    test('cupsRemainingWinner is null when absent', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData());
      expect(gs.cupsRemainingWinner, isNull);
    });

    test('parses gameMode from Firestore data', () {
      final gs = GameStatistics.fromFirestore(
          'g1', _baseData(gameMode: 'Tournament'));
      expect(gs.gameMode, 'Tournament');
    });

    test('defaults gameMode to Single Game when absent', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData());
      expect(gs.gameMode, 'Single Game');
    });

    test('parses specialRules from Firestore data', () {
      final gs = GameStatistics.fromFirestore(
          'g1', _baseData(specialRules: ['Bomb', 'Island']));
      expect(gs.specialRules, ['Bomb', 'Island']);
    });

    test('defaults specialRules to empty list when absent', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData());
      expect(gs.specialRules, isEmpty);
    });

    test('computes durationSeconds from timestamp and endedAt', () {
      final start = Timestamp(1000, 0);
      final end = Timestamp(1720, 0); // 720 seconds later
      final gs = GameStatistics.fromFirestore(
          'g1', _baseData(timestamp: start, endedAt: end));
      expect(gs.durationSeconds, 720);
    });

    test('durationSeconds is null when endedAt is absent', () {
      final start = Timestamp(1000, 0);
      final gs =
          GameStatistics.fromFirestore('g1', _baseData(timestamp: start));
      expect(gs.durationSeconds, isNull);
    });

    test('durationSeconds is null when both timestamps absent', () {
      final gs = GameStatistics.fromFirestore('g1', _baseData());
      expect(gs.durationSeconds, isNull);
    });

    test('parses id, winningTeam, and players correctly alongside new fields',
        () {
      final gs = GameStatistics.fromFirestore(
        'game42',
        _baseData(roundCount: 5, gameMode: 'Tournament'),
      );
      expect(gs.id, 'game42');
      expect(gs.winningTeam, 'Team 1');
      expect(gs.team1Players.length, 1);
      expect(gs.team1Players.first.name, 'Alice');
      expect(gs.roundCount, 5);
      expect(gs.gameMode, 'Tournament');
    });

    test('all new fields coexist with legacy fields correctly', () {
      final start = Timestamp(500, 0);
      final end = Timestamp(800, 0);
      final gs = GameStatistics.fromFirestore(
        'g1',
        _baseData(
          timestamp: start,
          endedAt: end,
          roundCount: 3,
          cupsRemainingWinner: 2,
          gameMode: 'Tournament',
          specialRules: ['Island'],
        ),
      );
      expect(gs.roundCount, 3);
      expect(gs.cupsRemainingWinner, 2);
      expect(gs.durationSeconds, 300);
      expect(gs.gameMode, 'Tournament');
      expect(gs.specialRules, ['Island']);
    });
  });

  group('UserStatsInGame', () {
    test('constructor stores date and player', () {
      final player = Player(name: 'Alice', score: 5.0);
      final date = DateTime.utc(2026, 3, 1);
      final stats = UserStatsInGame(date: date, player: player);
      expect(stats.date, date);
      expect(stats.player.name, 'Alice');
      expect(stats.player.score, 5.0);
    });
  });
}
