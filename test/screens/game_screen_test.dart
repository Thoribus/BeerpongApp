import 'package:beerpongapp/models/cup.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/game/game_screen.dart';
import 'package:beerpongapp/util/firestoreservice.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_screen_test.mocks.dart';

@GenerateMocks([FirestoreService, UserProvider, SharedPreferences])
void main() {
  late MockFirestoreService mockFirestoreService;
  late MockUserProvider mockUserProvider;
  late MockSharedPreferences mockSharedPreferences;
  late Player player1;
  late Player player2;
  late Player player3;
  late Player player4;
  late List<Player> team1Players;
  late List<Player> team2Players;
  late Map<String, bool> selectedRules;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockUserProvider = MockUserProvider();
    mockSharedPreferences = MockSharedPreferences();
    player1 = Player(name: 'Player 1');
    player2 = Player(name: 'Player 2');
    player3 = Player(name: 'Player 3');
    player4 = Player(name: 'Player 4');
    team1Players = [player1, player2];
    team2Players = [player3, player4];
    selectedRules = {'Deathcup': true, 'Island': true, 'Nachwurf': true};

    when(mockUserProvider.user).thenReturn(null);
    when(mockFirestoreService.saveGame(
            team1: anyNamed('team1'), team2: anyNamed('team2'), winner: anyNamed('winner')))
        .thenAnswer((_) async => <User>[]);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>.value(value: mockFirestoreService),
        ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
      ],
      child: MaterialApp(
        home: GameScreen(
          title: 'Test Game',
          players1: team1Players,
          players2: team2Players,
          selectedRules: selectedRules,
          startingTeam: true,
        ),
      ),
    );
  }

  testWidgets('GameScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Current Game'), findsOneWidget);
    expect(find.text('View Table'), findsOneWidget);
    expect(find.text('View Game Stats'), findsOneWidget);
  });

  testWidgets('GameScreen handles cup hit correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text(player1.name));
    await tester.pump();

    // Verify the state after a cup is hit
    expect(player1.cupsHit, isNotEmpty);
  });

  testWidgets('GameScreen saves and loads game state', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Simulate saving game state
    when(mockSharedPreferences.getString('team1Cups'))
        .thenReturn(Cup.encodeList(team1Players[0].cupsHit));
    when(mockSharedPreferences.getString('team2Cups'))
        .thenReturn(Cup.encodeList(team2Players[0].cupsHit));
    when(mockSharedPreferences.getString('team1Players'))
        .thenReturn(Player.encodeList(team1Players));
    when(mockSharedPreferences.getString('team2Players'))
        .thenReturn(Player.encodeList(team2Players));
    when(mockSharedPreferences.getBool('team1IsRearranged')).thenReturn(false);
    when(mockSharedPreferences.getBool('team2IsRearranged')).thenReturn(false);
    when(mockSharedPreferences.getBool('isTeamOneTurn')).thenReturn(true);
    when(mockSharedPreferences.getBool('islandShotActive')).thenReturn(false);

    await tester.tap(find.byTooltip('Airball'));
    await tester.pump();

    // Verify game state loading
    verify(mockSharedPreferences.getString('team1Cups')).called(1);
    verify(mockSharedPreferences.getString('team2Cups')).called(1);
    verify(mockSharedPreferences.getString('team1Players')).called(1);
    verify(mockSharedPreferences.getString('team2Players')).called(1);
    verify(mockSharedPreferences.getBool('team1IsRearranged')).called(1);
    verify(mockSharedPreferences.getBool('team2IsRearranged')).called(1);
    verify(mockSharedPreferences.getBool('isTeamOneTurn')).called(1);
    verify(mockSharedPreferences.getBool('islandShotActive')).called(1);
  });

  testWidgets('GameScreen handles game end correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    player1.incrementScore();
    player2.incrementScore();
    player3.incrementScore();
    player4.incrementScore();

    await tester.tap(find.text(player1.name));
    await tester.pump();

    // Simulate game end
    await tester.tap(find.byTooltip('Zugende'));
    await tester.pumpAndSettle();

    expect(find.text('Game Over'), findsOneWidget);
  });
}
