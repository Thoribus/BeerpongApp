import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/friends/friends_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

User _user(String id) => User(id: id, username: id);

FriendTile _tile({
  required User friend,
  VoidCallback? onChallenge,
}) {
  return FriendTile(
    friend: friend,
    currentUserId: 'u1',
    h2hGames: const <GameStatistics>[],
    onTap: () {},
    onRemove: () {},
    onChallenge: onChallenge,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FriendTile — challenge button', () {
    testWidgets('challenge button is absent when onChallenge is null',
        (tester) async {
      await tester.pumpWidget(_wrap(_tile(friend: _user('f1'))));

      expect(find.byKey(const Key('challenge-btn')), findsNothing);
      expect(find.text('Challenge'), findsNothing);
    });

    testWidgets('challenge button is visible when onChallenge is provided',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_tile(friend: _user('f1'), onChallenge: () {})));

      expect(find.byKey(const Key('challenge-btn')), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
    });

    testWidgets('tapping challenge button calls onChallenge callback',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(
          _wrap(_tile(friend: _user('f1'), onChallenge: () => called = true)));

      await tester.tap(find.byKey(const Key('challenge-btn')));
      expect(called, isTrue);
    });
  });

  group('User.usernameLower in toJson', () {
    test('toJson includes usernameLower for Firestore prefix search', () {
      final user = User(id: 'u1', username: 'Alice');
      expect(user.toJson()['usernameLower'], 'alice');
    });

    test('usernameLower is always lowercase regardless of username casing', () {
      final user = User(id: 'u1', username: 'BeerPongKing');
      expect(user.toJson()['usernameLower'], 'beerpongking');
    });
  });
}
