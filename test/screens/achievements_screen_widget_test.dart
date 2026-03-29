import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/screens/profile/achievements_screen.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/util/achievement_engine.dart';

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

    testWidgets('achievement grid shows cards for real catalogue titles',
        (tester) async {
      // Expand surface so GridView.builder builds all items eagerly.
      await tester.binding.setSurfaceSize(const Size(800, 12000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      // The achievement catalogue uses the real titles from AchievementEngine.
      // Verify a representative set from each category is rendered.
      final sampleTitles = ['Sniper', 'Pyromaniac', 'Winner', 'Social Butterfly', 'Airball Artist'];
      for (final title in sampleTitles) {
        expect(find.text(title), findsOneWidget,
            reason: 'Expected achievement card with title "$title"');
      }
    });

    testWidgets('renders all achievements from the catalogue', (tester) async {
      // Set a very tall surface so GridView.builder builds all items eagerly
      // and none are clipped by the viewport.
      await tester.binding.setSurfaceSize(const Size(800, 12000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildApp());
      await tester.pump();

      for (final def in AchievementEngine.allAchievements) {
        expect(find.text(def.title), findsOneWidget,
            reason: 'Expected achievement card for "${def.title}"');
      }
    });

    test('achievement catalogue covers all 5 categories', () {
      final categories = AchievementEngine.allAchievements
          .map((d) => d.category)
          .toSet();
      expect(categories.length, 5,
          reason: 'Expected one achievement per AchievementCategory');
    });

    testWidgets('no dummy PlayerOne text appears', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('PlayerOne'), findsNothing);
    });

    testWidgets('shows achievements count text', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      // The _StatChip in _LevelCard shows 'Achievements' as its sub-label.
      expect(find.textContaining('Achievements'), findsOneWidget);
    });
  });
}
