import 'package:beerpongapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:beerpongapp/screens/friends/friends_screen.dart';

Widget _buildTestApp(UserProvider userProvider) {
  return ChangeNotifierProvider<UserProvider>.value(
    value: userProvider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FriendsListScreen(),
    ),
  );
}

void main() {
  group('FriendsListScreen auth guard', () {
    testWidgets('shows sign-in prompt and button when user is null',
        (tester) async {
      final provider = UserProvider(); // user is null by default

      await tester.pumpWidget(_buildTestApp(provider));

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.text('Sign in to view your friends'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('does not render friends tab bar when signed out',
        (tester) async {
      final provider = UserProvider();

      await tester.pumpWidget(_buildTestApp(provider));

      expect(find.text('Friendlist'), findsNothing);
      expect(find.text('Leaderboard'), findsNothing);
      expect(find.text('Socials'), findsNothing);
    });

    testWidgets('shows people icon on signed-out state', (tester) async {
      final provider = UserProvider();

      await tester.pumpWidget(_buildTestApp(provider));
      await tester.pump();

      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });
}
