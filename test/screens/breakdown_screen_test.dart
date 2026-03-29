import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/games/breakdown_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

User _makeUser({
  int wins = 5,
  int losses = 3,
  double totalScore = 40,
  int totalThrows = 80,
  int hitLastCup = 2,
  int bounceAttempts = 4,
  int bounceMakes = 2,
  int islandAttempts = 3,
  int islandMakes = 1,
  int defended = 1,
  int onFire = 2,
}) =>
    User(
      id: 'u1',
      username: 'Alice',
      wins: wins,
      losses: losses,
      totalScore: totalScore,
      totalThrows: totalThrows,
      hitLastCup: hitLastCup,
      bounceAttempts: bounceAttempts,
      bounceMakes: bounceMakes,
      islandAttempts: islandAttempts,
      islandMakes: islandMakes,
      defended: defended,
      onFire: onFire,
    );

Player _makePlayer(String name, {bool isWinner = true}) => Player(
      name: name,
      score: 5,
      throws: 10,
      misses: 3,
      airballs: 1,
      isWinner: isWinner,
    );

GameStatistics _makeGame({
  required String winningTeam,
  required String username,
  bool userOnTeam1 = true,
  int? cupsRemainingWinner,
}) {
  final userPlayer =
      _makePlayer(username, isWinner: (winningTeam == 'Team 1') == userOnTeam1);
  final opponent = _makePlayer('Bob',
      isWinner: winningTeam == (userOnTeam1 ? 'Team 2' : 'Team 1'));
  return GameStatistics(
    id: 'g1',
    date: DateTime(2025, 1, 1),
    winningTeam: winningTeam,
    team1Players: userOnTeam1 ? [userPlayer] : [opponent],
    team2Players: userOnTeam1 ? [opponent] : [userPlayer],
    participants: [username, 'Bob'],
    cupsRemainingWinner: cupsRemainingWinner,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('BreakdownScreen — shot distribution', () {
    testWidgets('shows empty card when no throws', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(totalThrows: 0), games: const []),
      ));
      expect(find.text('No throws recorded yet.'), findsOneWidget);
    });

    testWidgets('shows donut chart when throws > 0', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: const []),
      ));
      expect(find.text('No throws recorded yet.'), findsNothing);
      expect(find.text('Hits'), findsOneWidget);
      expect(find.text('Misses'), findsOneWidget);
      expect(find.text('Airballs'), findsOneWidget);
    });
  });

  group('BreakdownScreen — special shots', () {
    testWidgets('shows Bounce Shot, Island Shot, Defended cards', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: const []),
      ));
      expect(find.text('Bounce Shot'), findsOneWidget);
      expect(find.text('Island Shot'), findsOneWidget);
      expect(find.text('Defended'), findsOneWidget);
    });

    testWidgets('Defended shows total-only format', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(defended: 3), games: const []),
      ));
      expect(find.text('3 total'), findsOneWidget);
    });
  });

  group('BreakdownScreen — win context', () {
    testWidgets('shows empty card when no wins', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(
            user: _makeUser(wins: 0), games: const []),
      ));
      expect(find.text('No wins recorded yet.'), findsOneWidget);
    });

    testWidgets('shows clutch rate when wins > 0', (tester) async {
      final games = [
        _makeGame(winningTeam: 'Team 1', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(hitLastCup: 1), games: games),
      ));
      expect(find.text('Clutch Rate'), findsOneWidget);
    });

    testWidgets('dominant win bar shown when cupsRemainingWinner >= 5',
        (tester) async {
      final games = [
        _makeGame(
          winningTeam: 'Team 1',
          username: 'Alice',
          cupsRemainingWinner: 7,
        ),
      ];
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: games),
      ));
      expect(find.text('Win Margin Distribution'), findsOneWidget);
      expect(find.text('Dominant (5+ cups)'), findsOneWidget);
    });
  });

  group('BreakdownScreen — head to head', () {
    testWidgets('shows empty card when no games', (tester) async {
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: const []),
      ));
      expect(find.text('No games recorded yet.'), findsOneWidget);
    });

    testWidgets('shows opponent row with W–L label', (tester) async {
      final games = [
        _makeGame(winningTeam: 'Team 1', username: 'Alice'),
        _makeGame(winningTeam: 'Team 2', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: games),
      ));
      // Bob appears as opponent row
      expect(find.text('Bob'), findsOneWidget);
      expect(find.textContaining('W –'), findsOneWidget);
    });

    testWidgets('caps at 5 opponents when more exist', (tester) async {
      final games = List.generate(7, (i) {
        final opponent = _makePlayer('Opp$i', isWinner: false);
        final alice = _makePlayer('Alice', isWinner: true);
        return GameStatistics(
          id: 'g$i',
          date: DateTime(2025, 1, i + 1),
          winningTeam: 'Team 1',
          team1Players: [alice],
          team2Players: [opponent],
          participants: ['Alice', 'Opp$i'],
        );
      });
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: games),
      ));
      // At most 5 opponent rows
      int oppCount = 0;
      for (int i = 0; i < 7; i++) {
        if (tester.widgetList(find.text('Opp$i')).isNotEmpty) oppCount++;
      }
      expect(oppCount, lessThanOrEqualTo(5));
    });

    testWidgets('win % is shown per opponent', (tester) async {
      // Alice wins 2, loses 1 against Bob
      final games = [
        _makeGame(winningTeam: 'Team 1', username: 'Alice'),
        _makeGame(winningTeam: 'Team 1', username: 'Alice'),
        _makeGame(winningTeam: 'Team 2', username: 'Alice'),
      ];
      await tester.pumpWidget(_wrap(
        BreakdownScreen(user: _makeUser(), games: games),
      ));
      // 2 wins, 1 loss → 67%
      expect(find.text('2 W – 1 L'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
    });
  });
}
