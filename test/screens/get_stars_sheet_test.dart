import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/shop/shop_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildShopApp(UserProvider provider) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: provider,
    child: const MaterialApp(home: ShopScreen()),
  );
}

UserProvider _signedIn({int stars = 100}) {
  final p = UserProvider();
  p.setUserForTesting(
    User(id: 'u1', username: 'Tester', stars: stars, purchasedItems: const []),
  );
  return p;
}

Future<void> _openGetStarsSheet(WidgetTester tester) async {
  // Tap "Get Stars" button in the shop header.
  await tester.tap(find.text('Get Stars'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('_GetStarsSheet', () {
    testWidgets('sheet opens when Get Stars is tapped', (tester) async {
      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      expect(find.text('Get Stars'), findsWidgets); // header + sheet title
    });

    testWidgets('Watch a short video row is visible', (tester) async {
      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      expect(find.text('Watch a short video'), findsOneWidget);
    });

    testWidgets('remaining count is shown in the video row', (tester) async {
      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      // Default state — no watches consumed yet.
      expect(find.textContaining('5 of 5'), findsOneWidget);
    });

    testWidgets('IAP pack rows are visible with Coming soon badge',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      expect(find.text('Starter Pack  ·  €1.99'), findsOneWidget);
      expect(find.text('Popular Pack  ·  €4.99'), findsOneWidget);
      expect(find.text('Mega Pack  ·  €9.99'), findsOneWidget);
      expect(find.text('Coming soon'), findsWidgets);
    });

    testWidgets('daily limit message shown when limit reached', (tester) async {
      // Pre-fill SharedPreferences to simulate limit reached today.
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({
        'ad_daily_count': 5,
        'ad_daily_date': todayStr,
      });

      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      // Wait for async _loadRemaining to finish.
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Daily limit reached'),
        findsOneWidget,
      );
    });

    testWidgets('sheet shows earn-for-free note', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildShopApp(_signedIn()));
      await tester.pump();

      await _openGetStarsSheet(tester);

      expect(find.textContaining('playing games'), findsOneWidget);
    });
  });
}
