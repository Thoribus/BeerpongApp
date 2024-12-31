import 'package:beerpongapp/screens/game_screen.dart';
import 'package:beerpongapp/screens/home_screen.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([SharedPreferences, UserProvider])
void main() {
  late MockSharedPreferences mockSharedPreferences;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockUserProvider = MockUserProvider();

    when(mockUserProvider.user).thenReturn(null);
    when(mockSharedPreferences.containsKey('team1Cups')).thenReturn(true);
    when(mockSharedPreferences.containsKey('team2Cups')).thenReturn(true);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: mockUserProvider),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen displays welcome text correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Welcome Back, User'), findsOneWidget);
  });

  testWidgets('HomeScreen displays New Game button',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('New Game'), findsOneWidget);
  });

  testWidgets('HomeScreen displays Resume button if a saved game exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('HomeScreen starts a new game correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(SelectionScreen), findsOneWidget);
  });

  testWidgets('HomeScreen resumes a saved game correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('HomeScreen shows confirmation dialog for starting new game',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Starting a new game will delete the current game. Do you want to continue?'),
        findsOneWidget);
  });

  testWidgets('HomeScreen clears saved game state correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start New Game'));
    await tester.pumpAndSettle();

    verify(mockSharedPreferences.remove('team1Cups')).called(1);
    verify(mockSharedPreferences.remove('team2Cups')).called(1);
    verify(mockSharedPreferences.remove('team1Players')).called(1);
    verify(mockSharedPreferences.remove('team2Players')).called(1);
    verify(mockSharedPreferences.remove('isTeamOneTurn')).called(1);
    verify(mockSharedPreferences.remove('islandShotActive')).called(1);
    verify(mockSharedPreferences.remove('team1IsRearranged')).called(1);
    verify(mockSharedPreferences.remove('team2IsRearranged')).called(1);
  });
}
