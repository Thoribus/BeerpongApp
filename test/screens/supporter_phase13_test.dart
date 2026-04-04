import 'package:beerpongapp/l10n/app_localizations.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/profile/account_screen.dart';
import 'package:beerpongapp/services/purchase_service.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

User _makeUser({bool isSupporter = false}) => User(
      id: 'u1',
      username: 'Tester',
      isSupporter: isSupporter,
      purchasedItems: const [],
    );

Widget _buildAccountApp(User user) {
  final provider = UserProvider()..setUserForTesting(user);
  return ChangeNotifierProvider<UserProvider>.value(
    value: provider,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccountScreen(),
    ),
  );
}

Widget _buildCardApp(User user) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: UserCard(
        user: user,
        onTitleTap: () {},
        onAvatarTap: () {},
      ),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── User model ─────────────────────────────────────────────────────────────

  group('User.isSupporter — model', () {
    test('defaults to false', () {
      expect(User(id: 'u1', username: 'A').isSupporter, isFalse);
    });

    test('toJson / fromJson round-trips isSupporter = true', () {
      final user = User(id: 'u1', username: 'A', isSupporter: true);
      final restored = User.fromJson({...user.toJson(), 'id': 'u1'});
      expect(restored.isSupporter, isTrue);
    });

    test('toJson / fromJson round-trips isSupporter = false', () {
      final user = User(id: 'u1', username: 'A', isSupporter: false);
      final restored = User.fromJson({...user.toJson(), 'id': 'u1'});
      expect(restored.isSupporter, isFalse);
    });

    test('fromJson defaults to false when field absent', () {
      final user = User.fromJson({'id': 'u1', 'username': 'A'});
      expect(user.isSupporter, isFalse);
    });

    test('copyWith updates isSupporter independently', () {
      final user = User(id: 'u1', username: 'A', isSupporter: false);
      final updated = user.copyWith(isSupporter: true);
      expect(updated.isSupporter, isTrue);
      expect(updated.username, 'A');
    });

    test('copyWith preserves isSupporter when not provided', () {
      final user = User(id: 'u1', username: 'A', isSupporter: true);
      final updated = user.copyWith(username: 'B');
      expect(updated.isSupporter, isTrue);
    });
  });

  // ── PurchaseService constants ───────────────────────────────────────────────

  group('PurchaseService — supporter pack', () {
    test('supporterPackId is in productIds', () {
      expect(
        PurchaseService.productIds.contains(PurchaseService.supporterPackId),
        isTrue,
      );
    });

    test('starsForProduct returns 300 for supporter pack', () {
      expect(
        PurchaseService.starsForProduct(PurchaseService.supporterPackId),
        300,
      );
    });
  });

  // ── UserCard badge ──────────────────────────────────────────────────────────

  group('UserCard — Supporter badge', () {
    testWidgets('shows Supporter chip when isSupporter = true', (tester) async {
      await tester.pumpWidget(_buildCardApp(_makeUser(isSupporter: true)));
      await tester.pump();
      expect(find.text('Supporter'), findsWidgets); // chip text
    });

    testWidgets('hides Supporter chip when isSupporter = false', (tester) async {
      await tester.pumpWidget(_buildCardApp(_makeUser(isSupporter: false)));
      await tester.pump();
      expect(find.text('Supporter'), findsNothing);
    });
  });

  // ── AccountScreen header badge ─────────────────────────────────────────────

  group('AccountScreen — Supporter badge in header', () {
    testWidgets('shows Supporter badge when isSupporter = true', (tester) async {
      await tester.pumpWidget(_buildAccountApp(_makeUser(isSupporter: true)));
      await tester.pump();
      expect(find.text('Supporter'), findsWidgets);
    });

    testWidgets('hides Supporter badge when isSupporter = false', (tester) async {
      await tester.pumpWidget(_buildAccountApp(_makeUser(isSupporter: false)));
      await tester.pump();
      expect(find.text('Supporter'), findsNothing);
    });
  });
}
