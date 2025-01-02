import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/compare_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Create sample users for testing
  final User currentUser = User(
    id: '1',
    username: 'CurrentUser',
    totalScore: 100.0,
    totalMisses: 50,
    totalAirballs: 10,
    totalThrows: 200,
    wins: 10,
    losses: 5,
  );

  final User friend = User(
    id: '2',
    username: 'FriendUser',
    totalScore: 80.0,
    totalMisses: 60,
    totalAirballs: 20,
    totalThrows: 180,
    wins: 8,
    losses: 7,
  );

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('ComparisonScreen displays user comparison correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: ComparisonScreen(currentUser: currentUser, friend: friend)));

    // Check if the usernames are displayed correctly
    expect(find.text('CurrentUser vs FriendUser'), findsOneWidget);

    // Check if the stats headers are displayed correctly
    expect(find.text('Stat'), findsOneWidget);
    expect(find.text('Total Score'), findsOneWidget);
    expect(find.text('Total Misses'), findsOneWidget);
    expect(find.text('Total Airballs'), findsOneWidget);
    expect(find.text('Total Throws'), findsOneWidget);
    expect(find.text('Wins'), findsOneWidget);
    expect(find.text('Losses'), findsOneWidget);
    expect(find.text('Win Rate'), findsOneWidget);

    // Check if the current user's stats are displayed correctly
    expect(find.text('100.0'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('${(currentUser.winRate * 100).toStringAsFixed(2)}%'), findsOneWidget);

    // Check if the friend's stats are displayed correctly
    expect(find.text('80.0'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('${(friend.winRate * 100).toStringAsFixed(2)}%'), findsOneWidget);
  });

  testWidgets('ComparisonScreen colors stats correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: ComparisonScreen(currentUser: currentUser, friend: friend)));

    // Check colors for total score (higher is better)
    Text currentUserScore = tester.widget(find.text('100.0'));
    Text friendScore = tester.widget(find.text('80.0'));
    expect(currentUserScore.style?.color, Colors.green);
    expect(friendScore.style?.color, Colors.red);

    // Check colors for total misses (lower is better)
    Text currentUserMisses = tester.widget(find.text('50').at(1));
    Text friendMisses = tester.widget(find.text('60'));
    expect(currentUserMisses.style?.color, Colors.green);
    expect(friendMisses.style?.color, Colors.red);

    // Check colors for total airballs (lower is better)
    Text currentUserAirballs = tester.widget(find.text('10'));
    Text friendAirballs = tester.widget(find.text('20'));
    expect(currentUserAirballs.style?.color, Colors.green);
    expect(friendAirballs.style?.color, Colors.red);

    // Check colors for total throws (higher is better)
    Text currentUserThrows = tester.widget(find.text('200'));
    Text friendThrows = tester.widget(find.text('180'));
    expect(currentUserThrows.style?.color, Colors.green);
    expect(friendThrows.style?.color, Colors.red);

    // Check colors for wins (higher is better)
    Text currentUserWins = tester.widget(find.text('10').at(1));
    Text friendWins = tester.widget(find.text('8'));
    expect(currentUserWins.style?.color, Colors.green);
    expect(friendWins.style?.color, Colors.red);

    // Check colors for losses (lower is better)
    Text currentUserLosses = tester.widget(find.text('5'));
    Text friendLosses = tester.widget(find.text('7'));
    expect(currentUserLosses.style?.color, Colors.green);
    expect(friendLosses.style?.color, Colors.red);

    // Check colors for win rate (higher is better)
    Text currentUserWinRate = tester.widget(find.text('${(currentUser.winRate * 100).toStringAsFixed(2)}%'));
    Text friendWinRate = tester.widget(find.text('${(friend.winRate * 100).toStringAsFixed(2)}%'));
    expect(currentUserWinRate.style?.color, Colors.green);
    expect(friendWinRate.style?.color, Colors.red);
  });
}
