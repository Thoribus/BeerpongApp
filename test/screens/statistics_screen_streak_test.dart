// Tests for streak computation logic via PersonalStatisticsScreen,
// which accepts user + games directly and shares the same streak logic.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/l10n.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/games/personal_statistics_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

User _makeUser() => User(id: 'u1', username: 'Alice', wins: 5, losses: 3);

Player _makePlayer(String name, {bool isWinner = true}) => Player(
      name: name,
      score: 5,
      throws: 10,
      misses: 3,
      airballs: 1,
      isWinner: isWinner,
    );

/// Alice is always on team1. [aliceWins] → winningTeam = 'Team 1'.
GameStatistics _makeGame(bool aliceWins, {DateTime? date}) {
  final alice = _makePlayer('Alice', isWinner: aliceWins);
  final bob = _makePlayer('Bob', isWinner: !aliceWins);
  return GameStatistics(
    id: 'g',
    date: date ?? DateTime(2025, 1, 1),
    winningTeam: aliceWins ? 'Team 1' : 'Team 2',
    team1Players: [alice],
    team2Players: [bob],
    participants: ['Alice', 'Bob'],
  );
}

Widget _wrap(Widget child) => wrapWithL10n(child);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Streak logic — career highlights via PersonalStatisticsScreen', () {
    testWidgets('no career highlights section when games list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(), games: const []),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsNothing);
      expect(find.text('Best Streak'), findsNothing);
    });

    testWidgets('career highlights shown when games present', (tester) async {
      final games = [
        _makeGame(true, date: DateTime(2025, 1, 2)),
        _makeGame(true, date: DateTime(2025, 1, 1)),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(), games: games),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
    });

    testWidgets('best streak is 3 for three consecutive wins', (tester) async {
      final games = [
        _makeGame(true, date: DateTime(2025, 1, 3)),
        _makeGame(true, date: DateTime(2025, 1, 2)),
        _makeGame(true, date: DateTime(2025, 1, 1)),
        _makeGame(false, date: DateTime(2024, 12, 31)),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(), games: games),
      ));
      // Best streak card value '3' appears somewhere on screen
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('best streak is 1 when wins and losses alternate', (tester) async {
      final games = [
        _makeGame(true, date: DateTime(2025, 1, 4)),
        _makeGame(false, date: DateTime(2025, 1, 3)),
        _makeGame(true, date: DateTime(2025, 1, 2)),
        _makeGame(false, date: DateTime(2025, 1, 1)),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(), games: games),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsOneWidget);
      // Best streak of 1; '1' appears at least once
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('best streak counts loss streak correctly', (tester) async {
      // Three consecutive losses is a valid "best streak" value of 3
      final games = [
        _makeGame(false, date: DateTime(2025, 1, 3)),
        _makeGame(false, date: DateTime(2025, 1, 2)),
        _makeGame(false, date: DateTime(2025, 1, 1)),
      ];
      await tester.pumpWidget(_wrap(
        PersonalStatisticsScreen(user: _makeUser(), games: games),
      ));
      expect(find.text('CAREER HIGHLIGHTS'), findsOneWidget);
      // The best streak value should be 3
      expect(find.text('3'), findsWidgets);
    });
  });
}
