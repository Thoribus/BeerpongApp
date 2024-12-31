import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'statistics_screen_test.mocks.dart';

@GenerateMocks([FirestoreService])
void main() {
  late MockFirestoreService mockFirestoreService;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: StatisticsScreen(),
    );
  }

  testWidgets('StatisticsScreen displays loading indicator while loading games',
      (WidgetTester tester) async {
    when(mockFirestoreService.retrieveGames()).thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StatisticsScreen displays error message when loading fails',
      (WidgetTester tester) async {
    when(mockFirestoreService.retrieveGames()).thenThrow(Exception('Failed to load games'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Failed to load games'), findsOneWidget);
  });

  testWidgets('StatisticsScreen displays game cards when games are loaded',
      (WidgetTester tester) async {
    final gameStatistics = GameStatistics(
      date: DateTime.now(),
      winningTeam: 'Team 1',
      team1Players: [Player(name: 'Player 1')],
      team2Players: [Player(name: 'Player 2')],
      participants: [],
    );
    when(mockFirestoreService.retrieveGames()).thenAnswer((_) async => [gameStatistics]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Game 1'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
  });

  testWidgets('StatisticsScreen navigates to GameDetailsPage when details button is pressed',
      (WidgetTester tester) async {
    final gameStatistics = GameStatistics(
      date: DateTime.now(),
      winningTeam: 'Team 1',
      team1Players: [Player(name: 'Player 1')],
      team2Players: [Player(name: 'Player 2')],
      participants: [],
    );
    when(mockFirestoreService.retrieveGames()).thenAnswer((_) async => [gameStatistics]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.byType(GameDetailsPage), findsOneWidget);
  });

  testWidgets('GameDetailsPage displays team statistics correctly', (WidgetTester tester) async {
    final player1 = Player(name: 'Player 1', score: 5, misses: 3, throws: 10, airballs: 2);
    final player2 = Player(name: 'Player 2', score: 3, misses: 5, throws: 10, airballs: 1);
    final gameStatistics = GameStatistics(
      date: DateTime.now(),
      winningTeam: 'Team 1',
      team1Players: [player1],
      team2Players: [player2],
      participants: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameDetailsPage(game: gameStatistics),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team 1'), findsOneWidget);
    expect(find.text('Team 2'), findsOneWidget);
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('GameDetailsPage toggles between team view and game stats view', (WidgetTester tester) async {
    final player1 = Player(name: 'Player 1', score: 5, misses: 3, throws: 10, airballs: 2);
    final player2 = Player(name: 'Player 2', score: 3, misses: 5, throws: 10, airballs: 1);
    final gameStatistics = GameStatistics(
      date: DateTime.now(),
      winningTeam: 'Team 1',
      team1Players: [player1],
      team2Players: [player2],
      participants: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameDetailsPage(game: gameStatistics),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team View'), findsOneWidget);
    expect(find.text('Game Stats'), findsOneWidget);

    await tester.tap(find.text('View Game Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Team Statistics'), findsOneWidget);

    await tester.tap(find.text('View Team'));
    await tester.pumpAndSettle();

    expect(find.text('Team View'), findsOneWidget);
    expect(find.text('Game Stats'), findsOneWidget);
  });
}
