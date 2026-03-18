import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/stats_helpers.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

User _user({
  int wins = 4,
  int losses = 2,
  double totalScore = 30,
  int totalThrows = 60,
  int totalMisses = 30,
  int hitLastCup = 2,
  int totalBounceAttempts = 6,
  int totalBounceMakes = 3,
  int totalIslandAttempts = 4,
  int totalIslandMakes = 2,
}) =>
    User(
      id: 'u1',
      username: 'Alice',
      wins: wins,
      losses: losses,
      totalScore: totalScore,
      totalThrows: totalThrows,
      totalMisses: totalMisses,
      hitLastCup: hitLastCup,
      totalBounceAttempts: totalBounceAttempts,
      totalBounceMakes: totalBounceMakes,
      totalIslandAttempts: totalIslandAttempts,
      totalIslandMakes: totalIslandMakes,
    );

Player _player(String name, {double score = 5, int throws = 10, bool isWinner = true}) =>
    Player(name: name, score: score, throws: throws, isWinner: isWinner, misses: 3, airballs: 1);

GameStatistics _game(bool aliceWins, {DateTime? date}) {
  final alice = _player('Alice', isWinner: aliceWins);
  final bob = _player('Bob', isWinner: !aliceWins);
  return GameStatistics(
    id: 'g',
    date: date ?? DateTime(2025, 1, 1),
    winningTeam: aliceWins ? 'Team 1' : 'Team 2',
    team1Players: [alice],
    team2Players: [bob],
    participants: ['Alice', 'Bob'],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('avgCupsPerGame', () {
    test('returns totalScore / gamesPlayed', () {
      expect(avgCupsPerGame(_user()), closeTo(5.0, 0.001)); // 30/6
    });
    test('returns 0 when no games', () {
      expect(avgCupsPerGame(_user(wins: 0, losses: 0)), 0.0);
    });
  });

  group('avgThrowsPerGame', () {
    test('returns totalThrows / gamesPlayed', () {
      expect(avgThrowsPerGame(_user()), closeTo(10.0, 0.001)); // 60/6
    });
    test('returns 0 when no games', () {
      expect(avgThrowsPerGame(_user(wins: 0, losses: 0)), 0.0);
    });
  });

  group('bounceConversion', () {
    test('returns bounceMakes / bounceAttempts', () {
      expect(bounceConversion(_user()), closeTo(0.5, 0.001)); // 3/6
    });
    test('returns 0 when no attempts', () {
      expect(bounceConversion(_user(totalBounceAttempts: 0, totalBounceMakes: 0)), 0.0);
    });
  });

  group('islandConversion', () {
    test('returns islandMakes / islandAttempts', () {
      expect(islandConversion(_user()), closeTo(0.5, 0.001)); // 2/4
    });
    test('returns 0 when no attempts', () {
      expect(islandConversion(_user(totalIslandAttempts: 0, totalIslandMakes: 0)), 0.0);
    });
  });

  group('winRate', () {
    test('returns wins / gamesPlayed', () {
      expect(winRate(_user()), closeTo(4 / 6, 0.001));
    });
    test('returns 0 when no games', () {
      expect(winRate(_user(wins: 0, losses: 0)), 0.0);
    });
  });

  group('hitRate', () {
    test('returns totalScore / totalThrows', () {
      expect(hitRate(_user()), closeTo(0.5, 0.001)); // 30/60
    });
    test('returns 0 when no throws', () {
      expect(hitRate(_user(totalThrows: 0, totalScore: 0)), 0.0);
    });
  });

  group('clutchRate', () {
    test('returns hitLastCup / gamesPlayed', () {
      expect(clutchRate(_user()), closeTo(2 / 6, 0.001));
    });
    test('returns 0 when no games', () {
      expect(clutchRate(_user(wins: 0, losses: 0)), 0.0);
    });
  });

  group('currentStreak', () {
    test('returns length 0 for empty list', () {
      final s = currentStreak([], 'Alice');
      expect(s.length, 0);
    });

    test('returns win streak of 2 for two consecutive wins', () {
      final games = [
        _game(true, date: DateTime(2025, 1, 2)),
        _game(true, date: DateTime(2025, 1, 1)),
        _game(false, date: DateTime(2024, 12, 31)),
      ];
      final s = currentStreak(games, 'Alice');
      expect(s.length, 2);
      expect(s.isWin, isTrue);
    });

    test('returns loss streak for consecutive losses', () {
      final games = [
        _game(false, date: DateTime(2025, 1, 3)),
        _game(false, date: DateTime(2025, 1, 2)),
        _game(true, date: DateTime(2025, 1, 1)),
      ];
      final s = currentStreak(games, 'Alice');
      expect(s.length, 2);
      expect(s.isWin, isFalse);
    });

    test('streak of 1 when first result differs from second', () {
      final games = [
        _game(true, date: DateTime(2025, 1, 2)),
        _game(false, date: DateTime(2025, 1, 1)),
      ];
      final s = currentStreak(games, 'Alice');
      expect(s.length, 1);
      expect(s.isWin, isTrue);
    });
  });

  group('bestSingleGameHitRate', () {
    test('returns 0 for empty games', () {
      expect(bestSingleGameHitRate([], 'Alice'), 0.0);
    });

    test('returns best hit rate across games', () {
      final games = [
        GameStatistics(
          id: 'g1',
          date: DateTime(2025, 1, 1),
          winningTeam: 'Team 1',
          team1Players: [_player('Alice', score: 8, throws: 10)],
          team2Players: [_player('Bob')],
          participants: ['Alice', 'Bob'],
        ),
        GameStatistics(
          id: 'g2',
          date: DateTime(2025, 1, 2),
          winningTeam: 'Team 1',
          team1Players: [_player('Alice', score: 5, throws: 10)],
          team2Players: [_player('Bob')],
          participants: ['Alice', 'Bob'],
        ),
      ];
      expect(bestSingleGameHitRate(games, 'Alice'), closeTo(0.8, 0.001));
    });
  });

  group('mostCupsInGame', () {
    test('returns 0 for empty games', () {
      expect(mostCupsInGame([], 'Alice'), 0);
    });

    test('returns highest cups scored in a single game', () {
      final games = [
        GameStatistics(
          id: 'g1',
          date: DateTime(2025, 1, 1),
          winningTeam: 'Team 1',
          team1Players: [_player('Alice', score: 7)],
          team2Players: [_player('Bob')],
          participants: ['Alice', 'Bob'],
        ),
        GameStatistics(
          id: 'g2',
          date: DateTime(2025, 1, 2),
          winningTeam: 'Team 1',
          team1Players: [_player('Alice', score: 3)],
          team2Players: [_player('Bob')],
          participants: ['Alice', 'Bob'],
        ),
      ];
      expect(mostCupsInGame(games, 'Alice'), 7);
    });
  });
}
