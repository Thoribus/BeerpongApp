import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/screens/shop/shop_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/models/user.dart';

Widget _buildApp(UserProvider provider) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: provider,
    child: const MaterialApp(home: ShopScreen()),
  );
}

void main() {
  group('ShopScreen — _ShopHeader', () {
    testWidgets('shows sign-in prompt when user is null', (tester) async {
      final provider = UserProvider();

      await tester.pumpWidget(_buildApp(provider));
      await tester.pump();

      expect(find.text('Sign in to earn Stars'), findsOneWidget);
      expect(find.text('Get Stars'), findsNothing);
    });

    testWidgets('shows star balance when user is signed in', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(
        User(id: 'u1', username: 'Tester', stars: 420),
      );

      await tester.pumpWidget(_buildApp(provider));
      await tester.pump();

      expect(find.text('420'), findsOneWidget);
      expect(find.text('Get Stars'), findsOneWidget);
      expect(find.text('Sign in to earn Stars'), findsNothing);
    });

    testWidgets('tapping Get Stars opens the bottom sheet', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(
        User(id: 'u1', username: 'Tester', stars: 100),
      );

      await tester.pumpWidget(_buildApp(provider));
      await tester.pump();

      await tester.tap(find.text('Get Stars'));
      await tester.pumpAndSettle();

      expect(find.text('Earn ⭐ stars to spend in the shop.'), findsOneWidget);
      expect(find.text('Watch a short video'), findsOneWidget);
      expect(find.text('Starter Pack  ·  €1.99'), findsOneWidget);
    });

    testWidgets('star icon is visible when user is signed in', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(User(id: 'u1', username: 'Tester'));

      await tester.pumpWidget(_buildApp(provider));
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });
  });
}
