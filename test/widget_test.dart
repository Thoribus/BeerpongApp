import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/game_screen.dart';
import 'package:flutter_application_1/models/player.dart';

void main() {
  group('GameScreen Widget Tests', () {
    testWidgets('Initial UI elements are present', (WidgetTester tester) async {
      // Create some sample players
      final List<Player> players1 = [Player(name: 'Player 1'), Player(name: 'Player 2')];
      final List<Player> players2 = [Player(name: 'Player 3'), Player(name: 'Player 4')];

      // Build our app and trigger a frame
      await tester.pumpWidget(MaterialApp(
        home: GameScreen(title: 'Beer Pong', players1: players1, players2: players2),
      ));

      // Verify that the title is present
      expect(find.text('Beer Pong'), findsOneWidget);

      // Verify that the player names are present
      expect(find.text('Player 1 Score: 0 Misses: 0'), findsOneWidget);
      expect(find.text('Player 2 Score: 0 Misses: 0'), findsOneWidget);
      expect(find.text('Player 3 Score: 0 Misses: 0'), findsOneWidget);
      expect(find.text('Player 4 Score: 0 Misses: 0'), findsOneWidget);

      // Verify that the current team is displayed
      expect(find.text('Current Team: Team 1'), findsOneWidget);
    });

    testWidgets('Tapping "Airball" button shows player selection dialog', (WidgetTester tester) async {
      // Create some sample players
      final List<Player> players1 = [Player(name: 'Player 1'), Player(name: 'Player 2')];
      final List<Player> players2 = [Player(name: 'Player 3'), Player(name: 'Player 4')];

      // Build our app and trigger a frame
      await tester.pumpWidget(MaterialApp(
        home: GameScreen(title: 'Beer Pong', players1: players1, players2: players2),
      ));

      // Tap the "Airball" button
      await tester.tap(find.byIcon(Icons.airplanemode_active));
      await tester.pumpAndSettle();

      // Verify that the player selection dialog is displayed
      expect(find.text('Select Player'), findsOneWidget);

      // Verify that player names are present in the dialog
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
    });

    testWidgets('Tapping "End Turn" shows confirmation dialog', (WidgetTester tester) async {
      // Create some sample players
      final List<Player> players1 = [Player(name: 'Player 1'), Player(name: 'Player 2')];
      final List<Player> players2 = [Player(name: 'Player 3'), Player(name: 'Player 4')];

      // Build our app and trigger a frame
      await tester.pumpWidget(MaterialApp(
        home: GameScreen(title: 'Beer Pong', players1: players1, players2: players2),
      ));

      // Tap the "End Turn" button
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();

      // Verify that the confirmation dialog is displayed
      expect(find.text('Confirm End Turn'), findsOneWidget);
      expect(find.text('Are you sure you want to end your turn?'), findsOneWidget);
    });

    testWidgets('Tapping "Undo" reverts the last action', (WidgetTester tester) async {
      // Create some sample players
      final List<Player> players1 = [Player(name: 'Player 1'), Player(name: 'Player 2')];
      final List<Player> players2 = [Player(name: 'Player 3'), Player(name: 'Player 4')];

      // Build our app and trigger a frame
      await tester.pumpWidget(MaterialApp(
        home: GameScreen(title: 'Beer Pong', players1: players1, players2: players2),
      ));

      // Simulate a state change
      // (e.g., incrementing the score of Player 1)
      await tester.runAsync(() async {
        players1[0].incrementScore();
        await tester.pump();
      });

      // Verify that the score has incremented
      expect(find.text('Player 1 Score: 1 Misses: 0'), findsOneWidget);

      // Tap the "Undo" button
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      // Verify that the score has reverted
      expect(find.text('Player 1 Score: 0 Misses: 0'), findsOneWidget);
    });
  });
}
