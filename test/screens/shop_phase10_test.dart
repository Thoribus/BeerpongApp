import 'package:beerpongapp/l10n/app_localizations.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/shop/shop_screen.dart';
import 'package:beerpongapp/util/shop_catalog.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildApp(UserProvider provider) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: provider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ShopScreen(),
    ),
  );
}

UserProvider _signedIn({int stars = 999, List<String> purchased = const []}) {
  final p = UserProvider();
  p.setUserForTesting(
    User(id: 'u1', username: 'Tester', stars: stars, purchasedItems: purchased),
  );
  return p;
}

void main() {
  group('ShopScreen Phase 10 — Avatar tab (borders + emblems)', () {
    testWidgets('renders border section header', (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();

      expect(find.text('Avatar Borders'), findsOneWidget);
    });

    testWidgets('renders emblem section header', (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();

      expect(find.text('Emblems & Medals'), findsOneWidget);
    });

    testWidgets('renders catalog item names in avatar tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();

      // Borders
      expect(find.text('Gold Frame'), findsOneWidget);
      expect(find.text('Neon Glow'), findsOneWidget);
      expect(find.text('Fire Ring'), findsOneWidget);
      // Emblems
      expect(find.text('Podium'), findsOneWidget);
      expect(find.text('Trophy'), findsOneWidget);
      expect(find.text('Death Cup'), findsOneWidget);
    });

    testWidgets('no old physical-product text appears', (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();

      expect(find.text('Beach Volleyball'), findsNothing);
      expect(find.text('Hiking Backpack'), findsNothing);
      expect(find.text('Tennis Racket'), findsNothing);
    });

    testWidgets('shows sign-in prompt when user is null', (tester) async {
      await tester.pumpWidget(_buildApp(UserProvider()));
      await tester.pump();

      expect(find.text('Sign in to browse the shop'), findsWidgets);
    });
  });

  group('ShopScreen Phase 10 — User Card tab (titles)', () {
    testWidgets('shows Titles section after tapping User Card tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();

      await tester.tap(find.text('User Card'));
      await tester.pumpAndSettle();

      expect(find.text('Titles'), findsOneWidget);
    });

    testWidgets('renders title items in User Card tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();
      await tester.tap(find.text('User Card'));
      await tester.pumpAndSettle();

      expect(find.text('Pong God'), findsOneWidget);
      expect(find.text('Beer Baron'), findsOneWidget);
      expect(find.text('Night Shifter'), findsOneWidget);
    });

    testWidgets('shows level-backgrounds info note', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();
      await tester.tap(find.text('User Card'));
      await tester.pumpAndSettle();

      expect(find.textContaining('level'), findsWidgets);
    });
  });

  group('ShopScreen Phase 10 — In-Game tab', () {
    testWidgets('shows Cup Skins and Table Themes sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();
      await tester.tap(find.text('In Game'));
      await tester.pumpAndSettle();

      expect(find.text('Cup Skins'), findsOneWidget);
      expect(find.text('Table Themes'), findsOneWidget);
    });

    testWidgets('renders in-game item names', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 3000));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildApp(_signedIn()));
      await tester.pump();
      await tester.tap(find.text('In Game'));
      await tester.pumpAndSettle();

      expect(find.text('Gold Cups'), findsOneWidget);
      expect(find.text('Neon Cups'), findsOneWidget);
      expect(find.text('Dark Table'), findsOneWidget);
      expect(find.text('Beach Table'), findsOneWidget);
    });
  });

  group('ShopScreen Phase 10 — ShopItemCard states', () {
    testWidgets('owned item shows checkmark icon', (tester) async {
      await tester.pumpWidget(_buildApp(
        _signedIn(purchased: ['border_gold']),
      ));
      await tester.pump();

      // The check icon should be visible
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('unowned affordable item shows star price chip', (tester) async {
      // stars=999 so all items are affordable
      await tester.pumpWidget(_buildApp(_signedIn(stars: 999)));
      await tester.pump();

      // Price chip contains a star icon + text — star_rounded icons present
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('unowned item with zero stars shows grey price chip',
        (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn(stars: 0)));
      await tester.pump();

      // Items render but are not affordable — still show price chips
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
    });

    testWidgets('tapping unowned item opens purchase dialog', (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn(stars: 999)));
      await tester.pump();

      // Tap the first non-owned item (Gold Frame)
      await tester.tap(find.text('Gold Frame'));
      await tester.pumpAndSettle();

      // Dialog appears with item name + buy button
      expect(find.text('Gold Frame'), findsWidgets);
      expect(find.textContaining('Buy for'), findsOneWidget);
    });

    testWidgets('purchase dialog shows "Get More Stars" when balance is low',
        (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn(stars: 0)));
      await tester.pump();

      await tester.tap(find.text('Gold Frame'));
      await tester.pumpAndSettle();

      expect(find.text('Get More Stars'), findsOneWidget);
      expect(find.textContaining('Buy for'), findsNothing);
    });

    testWidgets('purchase dialog cancel button closes dialog', (tester) async {
      await tester.pumpWidget(_buildApp(_signedIn(stars: 999)));
      await tester.pump();

      await tester.tap(find.text('Gold Frame'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Buy for'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Buy for'), findsNothing);
    });
  });

  group('ShopScreen Phase 10 — catalog coverage', () {
    test('all border IDs contain "border_"', () {
      final ids = ShopCatalog.byCategory(ShopItemCategory.border)
          .map((i) => i.id)
          .toList();
      expect(ids.every((id) => id.startsWith('border_')), isTrue);
    });

    test('all title IDs contain "title_"', () {
      final ids = ShopCatalog.byCategory(ShopItemCategory.title)
          .map((i) => i.id)
          .toList();
      expect(ids.every((id) => id.startsWith('title_')), isTrue);
    });

    test('inGame items split into cups and table sub-groups', () {
      final items = ShopCatalog.byCategory(ShopItemCategory.inGame);
      expect(items.any((i) => i.id.contains('cups')), isTrue);
      expect(items.any((i) => i.id.contains('table')), isTrue);
    });
  });
}
