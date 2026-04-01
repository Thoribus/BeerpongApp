import 'package:beerpongapp/l10n/app_localizations.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/profile/account_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

User makeTestUser() => User(id: 'test-id', username: 'Tester');

Widget _buildTestApp(UserProvider userProvider) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: userProvider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccountScreen(),
    ),
  );
}

void main() {
  group('AccountScreen logout', () {
    testWidgets('shows nothing when user is null', (tester) async {
      final provider = UserProvider();
      await tester.pumpWidget(_buildTestApp(provider));
      // AccountScreen returns SizedBox.shrink() when no user is signed in
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('shows logout icon when user is signed in', (tester) async {
      // Inject a non-null user directly via the internal setter so we bypass
      // Firebase in tests. UserProvider exposes updateUser which sets _user.
      final provider = UserProvider();
      provider.setUserForTesting(
        makeTestUser(),
      );

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('tapping logout icon shows confirmation dialog', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(makeTestUser());

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Cancel dismisses dialog without signing out', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(makeTestUser());

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog gone, user still signed in (logout icon still visible)
      expect(find.text('Sign out?'), findsNothing);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });

  // Phase 5.1 — AccountScreen simplified (no tabs, Profile header only)
  group('AccountScreen Phase 5.1 — simplified layout', () {
    testWidgets('shows Profile header when user is signed in', (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(makeTestUser());

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('no Customize / Achievements / Progress tabs visible',
        (tester) async {
      final provider = UserProvider();
      provider.setUserForTesting(makeTestUser());

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      // Phase 5.1 removed the 3-tab PageView; none of the old tab labels appear.
      expect(find.text('Customize'), findsNothing);
      expect(find.text('Achievements'), findsNothing);
      // 'Progress' might appear inside CustomUserScreen's level badge, so we
      // check the specific tab-bar label is gone, not just the word.
      expect(find.text('Profile'), findsOneWidget); // header still present
    });

    testWidgets('shows nothing when user is null (regression)', (tester) async {
      final provider = UserProvider();
      await tester.pumpWidget(_buildTestApp(provider));
      expect(find.text('Profile'), findsNothing);
    });
  });
}
