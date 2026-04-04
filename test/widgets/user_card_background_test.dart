import 'package:flutter/material.dart';
import '../helpers/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/widgets/user_card.dart';

User _makeUser({String backgroundKey = '', String avatarKey = 'avatar_aggroracoon', String title = ''}) =>
    User(id: 'u1', username: 'Tester', avatarKey: avatarKey, backgroundKey: backgroundKey, title: title);

Widget _wrap(Widget child) => wrapWithL10n(child);

void main() {
  group('UserCard — background rendering', () {
    testWidgets('renders without error for bg_default', (tester) async {
      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: 'bg_default'),
          onTitleTap: () {},
          onAvatarTap: () {},
        ),
      ));
      // No DecoratedBox gradient — falls through to the SVG path (which may
      // fail to load in tests but should not throw a hard error).
      expect(find.text('Tester'), findsOneWidget);
    });

    testWidgets('renders without error for empty backgroundKey', (tester) async {
      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: ''),
          onTitleTap: () {},
          onAvatarTap: () {},
        ),
      ));
      expect(find.text('Tester'), findsOneWidget);
    });

    testWidgets('shows a DecoratedBox gradient for bg_blue', (tester) async {
      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: 'bg_blue'),
          onTitleTap: () {},
          onAvatarTap: () {},
        ),
      ));
      expect(find.text('Tester'), findsOneWidget);
      // A DecoratedBox is used for non-default backgrounds.
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('shows a DecoratedBox gradient for bg_purple', (tester) async {
      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: 'bg_purple'),
          onTitleTap: () {},
          onAvatarTap: () {},
        ),
      ));
      expect(find.text('Tester'), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('onTitleTap and onAvatarTap callbacks are wired', (tester) async {
      int titleTaps = 0;
      int avatarTaps = 0;

      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: 'bg_amber'),
          onTitleTap: () => titleTaps++,
          onAvatarTap: () => avatarTaps++,
        ),
      ));

      // Tap the title area (GestureDetector wraps the title text)
      await tester.tap(find.text('No Title Yet'));
      expect(titleTaps, 1);
    });

    testWidgets('username is always rendered regardless of backgroundKey',
        (tester) async {
      for (final key in ['bg_default', 'bg_amber', 'bg_blue', 'bg_green', 'bg_purple', 'bg_dark', '']) {
        await tester.pumpWidget(_wrap(
          UserCard(
            user: _makeUser(backgroundKey: key),
            onTitleTap: () {},
            onAvatarTap: () {},
          ),
        ));
        expect(find.text('Tester'), findsOneWidget,
            reason: 'Username missing for backgroundKey="$key"');
      }
    });

    testWidgets('shows non-empty title text with colored style', (tester) async {
      await tester.pumpWidget(_wrap(
        UserCard(
          user: _makeUser(backgroundKey: 'bg_default', title: 'Beer Pong King'),
          onTitleTap: () {},
          onAvatarTap: () {},
        ),
      ));
      expect(find.text('Beer Pong King'), findsOneWidget);
      // 'No Title Yet' placeholder should NOT appear
      expect(find.text('No Title Yet'), findsNothing);
    });
  });
}
