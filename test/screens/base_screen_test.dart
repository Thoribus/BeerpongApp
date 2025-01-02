import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/screens/base_screen.dart';
import 'package:beerpongapp/screens/friendlist.dart';
import 'package:beerpongapp/screens/home_screen.dart';
import 'package:beerpongapp/screens/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('BaseScreen displays correct initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const BaseScreen(selectedIndex: 0)));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FriendsListScreen), findsNothing);
    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.byType(AccountScreen), findsNothing);
  });

  testWidgets('BaseScreen changes screen on bottom navigation tap', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const BaseScreen(selectedIndex: 0)));

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(find.byType(FriendsListScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.byType(AccountScreen), findsNothing);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.byType(FriendsListScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(AccountScreen), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.byType(StatisticsScreen), findsNothing);
    expect(find.byType(FriendsListScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('BaseScreen app bar title changes on page change', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const BaseScreen(selectedIndex: 0)));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Friendlist'), findsNothing);
    expect(find.text('Statistics'), findsNothing);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Friendlist'), findsOneWidget);
    expect(find.text('Statistics'), findsNothing);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Friendlist'), findsNothing);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
    expect(find.text('Friendlist'), findsNothing);
    expect(find.text('Statistics'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('BaseScreen maintains state across tabs', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const BaseScreen(selectedIndex: 0)));

    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(find.byType(FriendsListScreen), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
