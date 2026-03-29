import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/liveticker/live_game_stats_screen.dart';
import 'package:beerpongapp/screens/liveticker/match_stats_tab.dart';
import 'package:beerpongapp/models/team.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/cup.dart';

LiveGameData buildGameData() {
  // Team 1: two players with known stats
  final p1 = Player(name: 'Alice', score: 3.0, throws: 5, misses: 1, airballs: 0);
  final p2 = Player(name: 'Bob', score: 2.0, throws: 4, misses: 2, airballs: 1);

  // Team 2: two players
  final p3 = Player(name: 'Carol', score: 1.0, throws: 6, misses: 3, airballs: 2);
  final p4 = Player(name: 'Dave', score: 4.0, throws: 7, misses: 0, airballs: 0);

  final team1 = Team(
    color: Colors.blue,
    players: [p1, p2],
    cups: List.generate(10, (i) => Cup(index: i, color: Colors.blue)),
  );
  final team2 = Team(
    color: Colors.red,
    players: [p3, p4],
    cups: List.generate(10, (i) => Cup(index: i, color: Colors.red)),
  );

  return LiveGameData(
    team1: team1,
    team2: team2,
    gameId: 'test-game',
    gameStart: DateTime(2024, 1, 1),
  );
}

void main() {
  group('MatchStatsTab widget', () {
    testWidgets('shows all stat labels', (tester) async {
      final gameData = buildGameData();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MatchStatsTab(gameData: gameData))),
      );

      expect(find.text('Score'), findsOneWidget);
      expect(find.text('Throws'), findsOneWidget);
      expect(find.text('Airballs'), findsOneWidget);
      expect(find.text('Misses'), findsOneWidget);
      expect(find.text('Accuracy %'), findsOneWidget);
    });

    testWidgets('displays aggregated team1 score (sum across players)',
        (tester) async {
      // p1.score=3 + p2.score=2 = 5
      final gameData = buildGameData();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MatchStatsTab(gameData: gameData))),
      );

      // The score row shows "5" for team1 (left side)
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('displays aggregated team1 throws (sum across players)',
        (tester) async {
      // p1.throws=5 + p2.throws=4 = 9
      final gameData = buildGameData();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MatchStatsTab(gameData: gameData))),
      );

      expect(find.text('9'), findsWidgets);
    });

    testWidgets('displays aggregated team2 airballs (sum across players)',
        (tester) async {
      // p3.airballs=2 + p4.airballs=0 = 2
      final gameData = buildGameData();

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MatchStatsTab(gameData: gameData))),
      );

      // "2" will appear for team2 airballs
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('renders without overflow errors', (tester) async {
      final gameData = buildGameData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: MatchStatsTab(gameData: gameData),
            ),
          ),
        ),
      );

      // If there were layout errors the test would fail automatically
      expect(tester.takeException(), isNull);
    });
  });
}
