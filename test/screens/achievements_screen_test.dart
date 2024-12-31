import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/achievements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  User testUser = User(
    id: 'test_id',
    username: 'test_user',
    wins: 10,
    losses: 5,
  );

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('AchievementsScreen displays user achievements', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: AchievementsScreen(user: testUser)));

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('Wins'), findsOneWidget);
    expect(find.text('Losses'), findsOneWidget);
    expect(find.text('10 / 50'), findsOneWidget);
    expect(find.text('5 / 50'), findsOneWidget);
  });

  testWidgets('AchievementsScreen shows progress indicators', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: AchievementsScreen(user: testUser)));

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    LinearProgressIndicator winsProgress = tester.widget(find.byType(LinearProgressIndicator).first);
    LinearProgressIndicator lossesProgress = tester.widget(find.byType(LinearProgressIndicator).last);

    expect(winsProgress.value, 10 / 50);
    expect(lossesProgress.value, 5 / 50);
  });

  testWidgets('AchievementsScreen has correct icon for achievements', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: AchievementsScreen(user: testUser)));

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('AchievementsScreen has correct text style', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: AchievementsScreen(user: testUser)));

    Text winsText = tester.widget(find.text('Wins'));
    Text lossesText = tester.widget(find.text('Losses'));

    expect(winsText.style?.color, Colors.amber);
    expect(winsText.style?.fontSize, 20);
    expect(winsText.style?.fontWeight, FontWeight.bold);

    expect(lossesText.style?.color, Colors.amber);
    expect(lossesText.style?.fontSize, 20);
    expect(lossesText.style?.fontWeight, FontWeight.bold);
  });
}
