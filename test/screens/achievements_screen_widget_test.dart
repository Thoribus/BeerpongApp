import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/models/user.dart';

void main() {
  group('AchievementsScreen widget', () {
    final testUser = User(
      id: 'u1',
      username: 'TestUser',
      wins: 30,
      losses: 10,
      totalScore: 120.0,
      totalMisses: 40,
      friends: ['f1', 'f2'],
      unlockedTitles: [],
    );

    Widget buildApp() => MaterialApp(
          home: AchievementsScreen(user: testUser),
        );

    testWidgets('renders user username in the screen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('TestUser'), findsOneWidget);
    });

    testWidgets('achievement grid shows 5 cards (one per achievement)',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // Each achievement is rendered as a Card with the achievement title.
      // getAchievements returns 5 entries.
      final achievementTitles = ['Wins', 'Losses', 'Friendships', 'Champion', 'Misses'];
      for (final title in achievementTitles) {
        expect(find.text(title), findsOneWidget,
            reason: 'Expected achievement card with title "$title"');
      }
    });

    testWidgets('no dummy PlayerOne text appears', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('PlayerOne'), findsNothing);
    });

    testWidgets('shows achievements count text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // The user card shows "X / 5 Achievements"
      expect(find.textContaining('Achievements'), findsOneWidget);
    });
  });
}
