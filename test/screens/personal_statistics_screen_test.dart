import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/games/personal_statistics_screen.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

User _makeUser({
  int wins = 5,
  int losses = 3,
  double totalScore = 40,
  int totalThrows = 80,
  int onFire = 2,
  int defended = 1,
  int hitLastCup = 3,
  int totalHeatingUp = 5,
  int bounceAttempts = 4,
  int bounceMakes = 2,
  int islandMakes = 1,
  int nightGames = 2,
}) =>
    User(
      id: 'u1',
      username: 'Alice',
      wins: wins,
      losses: losses,
      totalScore: totalScore,
      totalThrows: totalThrows,
      onFire: onFire,
      defended: defended,
      hitLastCup: hitLastCup,
      totalHeatingUp: totalHeatingUp,
      bounceAttempts: bounceAttempts,
      bounceMakes: bounceMakes,
      islandMakes: islandMakes,
      nightGames: nightGames,
      cupsHitCount: {'0': 3, '1': 2, '9': 1},
    );

Player _makePlayer(String name, {bool isWinner = true, double score = 5}) =>
    Player(
      name: name,
      score: score,
      throws: 10,
      misses: 3,
      airballs: 1,
      isWinner: isWinner,
    );

GameStatistics _makeGame({
  required String winner,
  required String username,
  bool userOnTeam1 = true,
}) {
  final userPlayer = _makePlayer(username, isWinner: winner == 'Team 1');
  final opponent = _makePlayer('Bob', isWinner: winner == 'Team 2');
  return GameStatistics(
    id: 'g1',
    date: DateTime(2025, 1, 1),
    winningTeam: winner,
    team1Players: userOnTeam1 ? [userPlayer] : [opponent],
    team2Players: userOnTeam1 ? [opponent] : [userPlayer],
    participants: [username, 'Bob'],
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final user = _makeUser();

  group('PersonalStatisticsScreen — stat grid', () {
    testWidgets('shows 13 stat tiles including Night Games', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: const []),
      ));
      // Phase 6 tiles (surface hidden stats)
      expect(find.text('Defended'), findsOneWidget);
      expect(find.text('Heating Up'), findsOneWidget);
      expect(find.text('Last Cup'), findsOneWidget);
      expect(find.text('Avg/Game'), findsOneWidget);
      // Phase 6.1 — new Night Games tile
      expect(find.text('Night Games'), findsOneWidget);
      // Legacy tiles
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('Losses'), findsOneWidget);
      expect(find.text('Win Rate'), findsOneWidget);
      expect(find.text('Hit Rate'), findsOneWidget);
      expect(find.text('Cups Hit'), findsOneWidget);
      expect(find.text('On Fire'), findsOneWidget);
      expect(find.text('Bounce%'), findsOneWidget);
      expect(find.text('Islands'), findsOneWidget);
    });

    testWidgets('Night Games tile shows nightGames value', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(
            user: _makeUser(nightGames: 7), games: const []),
      ));
      expect(find.text('Night Games'), findsOneWidget);
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('Defended tile shows user.defended value', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(defended: 7), games: const []),
      ));
      expect(find.text('7'), findsWidgets); // 7 appears at least once
    });

    testWidgets('Heating Up tile shows totalHeatingUp value', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(
            user: _makeUser(totalHeatingUp: 9), games: const []),
      ));
      expect(find.text('9'), findsWidgets);
    });

    testWidgets('Last Cup tile shows hitLastCup value', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(hitLastCup: 4), games: const []),
      ));
      expect(find.text('4'), findsWidgets);
    });

    testWidgets('Avg/Game tile shows correct value for 0 games', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(
          user: _makeUser(wins: 0, losses: 0, totalScore: 0),
          games: const [],
        ),
      ));
      // 0 games → no avg possible — value is '0.0'
      expect(find.text('Avg/Game'), findsOneWidget);
    });
  });

  group('PersonalStatisticsScreen — recent form strip', () {
    testWidgets('shows up to 10 recent form circles', (tester) async {
      final games = List.generate(
        12,
        (i) => _makeGame(
          winner: i % 2 == 0 ? 'Team 1' : 'Team 2',
          username: 'Alice',
        ),
      );
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: games),
      ));
      // Should show exactly 10 circles (capped at 10), each labelled W or L
      final wFinders = find.text('W');
      final lFinders = find.text('L');
      final total = tester.widgetList(wFinders).length +
          tester.widgetList(lFinders).length;
      expect(total, 10);
    });

    testWidgets('does not show form strip when games list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: const []),
      ));
      expect(find.text('W'), findsNothing);
      expect(find.text('L'), findsNothing);
    });
  });

  group('PersonalStatisticsScreen — derived chips row', () {
    testWidgets('shows derived chips when games > 0', (tester) async {
      final games = [
        _makeGame(winner: 'Team 1', username: 'Alice'),
        _makeGame(winner: 'Team 2', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: games),
      ));
      // Chips show cups/game and throws/game units
      expect(find.textContaining('cups/game'), findsOneWidget);
      expect(find.textContaining('throws/game'), findsOneWidget);
    });

    testWidgets('hides chips row when no games played', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(
          user: _makeUser(wins: 0, losses: 0),
          games: const [],
        ),
      ));
      expect(find.textContaining('cups/game'), findsNothing);
    });
  });

  group('PersonalStatisticsScreen — career highlights', () {
    testWidgets('shows CAREER HIGHLIGHTS section when games present',
        (tester) async {
      final games = [
        _makeGame(winner: 'Team 1', username: 'Alice'),
        _makeGame(winner: 'Team 1', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: games),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('Best Hit Rate'), findsOneWidget);
      expect(find.text('Most Cups'), findsOneWidget);
    });

    testWidgets('hides career highlights when no games', (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: const []),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsNothing);
    });

    testWidgets('best streak is 2 for two consecutive wins', (tester) async {
      final games = [
        _makeGame(winner: 'Team 1', username: 'Alice'),
        _makeGame(winner: 'Team 1', username: 'Alice'),
        _makeGame(winner: 'Team 2', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: user, games: games),
      ));
      // Best streak card value should be '2'
      expect(find.text('2'), findsWidgets);
    });
  });
}
