import '../models/game_statistics.dart';
import '../models/user.dart';

/// Average cups hit per game (totalScore / gamesPlayed).
double avgCupsPerGame(User u) {
  final games = u.wins + u.losses;
  return games > 0 ? u.totalScore / games : 0;
}

/// Average throws per game (totalThrows / gamesPlayed).
double avgThrowsPerGame(User u) {
  final games = u.wins + u.losses;
  return games > 0 ? u.totalThrows / games : 0;
}

/// Bounce shot conversion rate (bounceMakes / bounceAttempts), 0–1.
double bounceConversion(User u) => u.bounceAttempts > 0
    ? u.bounceMakes / u.bounceAttempts
    : 0;

/// Island shot conversion rate (islandMakes / islandAttempts), 0–1.
double islandConversion(User u) => u.islandAttempts > 0
    ? u.islandMakes / u.islandAttempts
    : 0;

/// Win rate (wins / gamesPlayed), 0–1.
double winRate(User u) {
  final games = u.wins + u.losses;
  return games > 0 ? u.wins / games : 0;
}

/// Hit rate (totalScore / totalThrows), 0–1.
double hitRate(User u) =>
    u.totalThrows > 0 ? u.totalScore / u.totalThrows : 0;

/// Clutch rate — last-cup hits per game played, 0–1.
double clutchRate(User u) {
  final games = u.wins + u.losses;
  return games > 0 ? u.hitLastCup / games : 0;
}

/// Current win/loss streak derived from sorted game history.
/// Returns `(length: N, isWin: bool)`.
({int length, bool isWin}) currentStreak(
    List<GameStatistics> games, String username) {
  final sorted = [...games]..sort((a, b) => b.date.compareTo(a.date));
  if (sorted.isEmpty) return (length: 0, isWin: true);
  bool won(GameStatistics g) => g.winningTeam == 'Team 1'
      ? g.team1Players.any((p) => p.name == username)
      : g.team2Players.any((p) => p.name == username);
  final firstWon = won(sorted.first);
  int count = 0;
  for (final g in sorted) {
    if (won(g) == firstWon) {
      count++;
    } else {
      break;
    }
  }
  return (length: count, isWin: firstWon);
}

/// Best single-game hit rate (score / throws) for [username] across all [games].
/// Returns 0 if no games or no throws.
double bestSingleGameHitRate(List<GameStatistics> games, String username) {
  double best = 0;
  for (final g in games) {
    final allPlayers = g.team1Players + g.team2Players;
    for (final p in allPlayers) {
      if (p.name == username && p.throws > 0) {
        final rate = p.score / p.throws;
        if (rate > best) best = rate;
      }
    }
  }
  return best;
}

/// Most cups hit by [username] in a single game.
/// Returns 0 if no games.
int mostCupsInGame(List<GameStatistics> games, String username) {
  int best = 0;
  for (final g in games) {
    final allPlayers = g.team1Players + g.team2Players;
    for (final p in allPlayers) {
      if (p.name == username) {
        final cups = p.score.toInt();
        if (cups > best) best = cups;
      }
    }
  }
  return best;
}
