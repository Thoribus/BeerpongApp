import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/screens/selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([VoidCallback])
void main() {
  late MockVoidCallback mockOnReturn;

  setUp(() {
    mockOnReturn = MockVoidCallback();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SelectionScreen(onReturn: mockOnReturn),
    );
  }

  testWidgets('SelectionScreen displays correct default texts',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Customize your Game'), findsOneWidget);
    expect(
        find.text('Learn about different game modes, rules, and more!'),
        findsOneWidget);
    expect(find.text('Number of Players:'), findsOneWidget);
    expect(find.text('Single Game'), findsOneWidget);
    expect(find.text('Tournament'), findsOneWidget);
    expect(find.text('Select Special Rules'), findsOneWidget);
    expect(find.text('Select Starting Team'), findsOneWidget);
  });

  testWidgets('SelectionScreen displays players section when "Players" filter is selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Players'));
    await tester.pump();

    expect(find.text('Number of Players:'), findsOneWidget);
  });

  testWidgets('SelectionScreen displays game mode section when "Game Mode" filter is selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Game Mode'));
    await tester.pump();

    expect(find.text('Select Game Mode'), findsOneWidget);
    expect(find.text('Single Game'), findsOneWidget);
    expect(find.text('Tournament'), findsOneWidget);
  });

  testWidgets('SelectionScreen displays special rules section when "Special Rules" filter is selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Special Rules'));
    await tester.pump();

    expect(find.text('Select Special Rules'), findsOneWidget);
    expect(find.text('Deathcup'), findsOneWidget);
    expect(find.text('Island'), findsOneWidget);
    expect(find.text('Nachwurf'), findsOneWidget);
  });

  testWidgets('SelectionScreen displays starting team section when "Starting Team" filter is selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Starting Team'));
    await tester.pump();

    expect(find.text('Select Starting Team'), findsOneWidget);
    expect(find.text('Team Blue'), findsOneWidget);
    expect(find.text('Team Red'), findsOneWidget);
  });

  testWidgets('SelectionScreen enables start game button when both teams have players',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Players'));
    await tester.pump();

    await tester.tap(find.text('Add Players'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK')); // Confirm adding players
    await tester.pumpAndSettle();

    expect(find.text('Start Game'), findsOneWidget);
    expect(
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Start Game'))
            .enabled,
        isTrue);
  });

  testWidgets('SelectionScreen disables start game button when teams are empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Start Game'), findsOneWidget);
    expect(
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Start Game'))
            .enabled,
        isFalse);
  });

  testWidgets('SelectionScreen starts a new game correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.tap(find.text('Players'));
    await tester.pump();

    await tester.tap(find.text('Add Players'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK')); // Confirm adding players
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
  });
}
