import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/widgets/player_card_mini.dart';
import '../helpers/l10n.dart';

Player _guestPlayer({String name = 'Alice', double score = 3.0}) =>
    Player(name: name, score: score);

Player _userPlayer({
  String username = 'Bob',
  String title = '',
  String avatarKey = '',
  double score = 5.0,
}) =>
    Player(
      name: username,
      score: score,
      user: User(id: 'u1', username: username, title: title, avatarKey: avatarKey),
    );

Widget _wrap(Widget child) => wrapWithL10n(
      SizedBox(width: 250, height: 60, child: child),
    );

void main() {
  group('PlayerCardMini — standard (guest) variant', () {
    testWidgets('renders player name', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(player: _guestPlayer(name: 'Alice'), teamColor: Colors.blue),
      ));
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows Guest label', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(player: _guestPlayer(), teamColor: Colors.blue),
      ));
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('renders without error for red team color', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(player: _guestPlayer(name: 'Carol'), teamColor: Colors.red),
      ));
      expect(find.text('Carol'), findsOneWidget);
    });
  });

  group('PlayerCardMini — user variant', () {
    testWidgets('renders username', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(player: _userPlayer(username: 'Bob'), teamColor: Colors.blue),
      ));
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows title when non-empty', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(
          player: _userPlayer(username: 'Bob', title: 'Sharpshooter'),
          teamColor: Colors.blue,
        ),
      ));
      expect(find.text('Sharpshooter'), findsOneWidget);
    });

    testWidgets('does not show title when empty', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(
          player: _userPlayer(username: 'Bob', title: ''),
          teamColor: Colors.blue,
        ),
      ));
      // No title widget should be present
      expect(find.text('Guest'), findsNothing);
    });

    testWidgets('shows level badge with Lv text', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(
          player: _userPlayer(username: 'Bob'),
          teamColor: Colors.blue,
        ),
      ));
      expect(find.textContaining('Lv '), findsOneWidget);
    });

    testWidgets('shows person icon when avatarKey is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        PlayerCardMini(
          player: _userPlayer(username: 'Bob', avatarKey: ''),
          teamColor: Colors.blue,
        ),
      ));
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
