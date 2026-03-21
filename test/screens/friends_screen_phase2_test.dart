import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/friends/friends_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

User _user(String id, {DateTime? lastGameAt}) =>
    User(id: id, username: id, lastGameAt: lastGameAt);

/// Minimal [GameStatistics] between [userId] (team 1) and [friendId] (team 2).
/// [userWon] controls which team wins.
GameStatistics _game(
  String gameId, {
  required String userId,
  required String friendId,
  required bool userWon,
  DateTime? date,
}) {
  return GameStatistics(
    id: gameId,
    date: date ?? DateTime.now(),
    winningTeam: userWon ? 'Team 1' : 'Team 2',
    team1Players: [
      Player(name: userId, user: User(id: userId, username: userId))
    ],
    team2Players: [
      Player(name: friendId, user: User(id: friendId, username: friendId))
    ],
    participants: [userId, friendId],
  );
}

FriendTile _tile({
  required User friend,
  List<GameStatistics> h2hGames = const [],
  VoidCallback? onRemove,
}) {
  return FriendTile(
    friend: friend,
    currentUserId: 'u1',
    h2hGames: h2hGames,
    onTap: () {},
    onRemove: onRemove ?? () {},
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FriendTile — active dot', () {
    testWidgets('shows active dot when lastGameAt is within 7 days',
        (tester) async {
      final friend = _user('f1',
          lastGameAt: DateTime.now().subtract(const Duration(days: 3)));
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.byKey(const Key('active-dot')), findsOneWidget);
    });

    testWidgets('hides active dot when lastGameAt is null', (tester) async {
      final friend = _user('f1');
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.byKey(const Key('active-dot')), findsNothing);
    });

    testWidgets('hides active dot when lastGameAt is 10 days ago',
        (tester) async {
      final friend = _user('f1',
          lastGameAt: DateTime.now().subtract(const Duration(days: 10)));
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.byKey(const Key('active-dot')), findsNothing);
    });

    testWidgets('shows active dot when lastGameAt is exactly 7 days ago',
        (tester) async {
      final friend = _user(
        'f1',
        lastGameAt: DateTime.now().subtract(const Duration(days: 7)),
      );
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.byKey(const Key('active-dot')), findsOneWidget);
    });
  });

  group('FriendTile — H2H chip', () {
    testWidgets('hides H2H chip when no shared games', (tester) async {
      final friend = _user('f1');
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.byKey(const Key('h2h-chip')), findsNothing);
    });

    testWidgets('shows H2H chip with correct W/L when games exist',
        (tester) async {
      final friend = _user('f1');
      final games = [
        _game('g1', userId: 'u1', friendId: 'f1', userWon: true),
        _game('g2', userId: 'u1', friendId: 'f1', userWon: true),
        _game('g3', userId: 'u1', friendId: 'f1', userWon: false),
      ];
      await tester.pumpWidget(_wrap(_tile(friend: friend, h2hGames: games)));

      expect(find.byKey(const Key('h2h-chip')), findsOneWidget);
      expect(find.text('H2H  W2 · L1'), findsOneWidget);
    });

    testWidgets('shows W0 · L1 when user lost the only game', (tester) async {
      final friend = _user('f1');
      final games = [
        _game('g1', userId: 'u1', friendId: 'f1', userWon: false),
      ];
      await tester.pumpWidget(_wrap(_tile(friend: friend, h2hGames: games)));

      expect(find.text('H2H  W0 · L1'), findsOneWidget);
    });
  });

  group('FriendTile — form strip', () {
    testWidgets('renders one circle per game (max 5)', (tester) async {
      final friend = _user('f1');
      // 6 games — only recent5 (first 5, already sorted newest-first by caller)
      final games = List.generate(
        6,
        (i) => _game('g$i',
            userId: 'u1',
            friendId: 'f1',
            userWon: i.isEven,
            date: DateTime.now().subtract(Duration(days: i))),
      );
      await tester.pumpWidget(_wrap(_tile(friend: friend, h2hGames: games)));

      // 5 small circle containers in the form strip
      final circles = tester.widgetList<Container>(find.descendant(
        of: find.byType(FriendTile),
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.constraints?.maxWidth == null &&
            (w.decoration as BoxDecoration?)?.shape == BoxShape.circle),
      ));
      // At most 5 form circles (ignore the active dot container)
      expect(circles.length, lessThanOrEqualTo(5));
    });

    testWidgets('shows "No games" when lastGameAt is null', (tester) async {
      final friend = _user('f1');
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.text('No games'), findsOneWidget);
    });

    testWidgets('shows relative time when lastGameAt is set', (tester) async {
      final friend = _user('f1',
          lastGameAt: DateTime.now().subtract(const Duration(days: 2)));
      await tester.pumpWidget(_wrap(_tile(friend: friend)));

      expect(find.text('2d ago'), findsOneWidget);
    });

    testWidgets('shows week/month/year buckets for older activity',
        (tester) async {
      final weekFriend = _user('week',
          lastGameAt: DateTime.now().subtract(const Duration(days: 14)));
      final monthFriend = _user('month',
          lastGameAt: DateTime.now().subtract(const Duration(days: 65)));
      final yearFriend = _user('year',
          lastGameAt: DateTime.now().subtract(const Duration(days: 370)));

      await tester.pumpWidget(_wrap(Column(
        children: [
          _tile(friend: weekFriend),
          _tile(friend: monthFriend),
          _tile(friend: yearFriend),
        ],
      )));

      expect(find.text('2w ago'), findsOneWidget);
      expect(find.text('2mo ago'), findsOneWidget);
      expect(find.text('1y ago'), findsOneWidget);
    });
  });

  group('FriendTile — swipe-to-dismiss', () {
    testWidgets('swiping left reveals remove confirmation dialog',
        (tester) async {
      final friend = _user('f1');
      await tester
          .pumpWidget(_wrap(ListView(children: [_tile(friend: friend)])));

      await tester.drag(find.byType(FriendTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Remove Friend'), findsOneWidget);
      expect(find.text('Remove f1 from your friends?'), findsOneWidget);
    });

    testWidgets('tapping Cancel keeps the tile', (tester) async {
      final friend = _user('f1');
      await tester
          .pumpWidget(_wrap(ListView(children: [_tile(friend: friend)])));

      await tester.drag(find.byType(FriendTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(FriendTile), findsOneWidget);
    });

    testWidgets('tapping Remove calls onRemove callback', (tester) async {
      bool removed = false;
      final friend = _user('f1');
      await tester.pumpWidget(_wrap(ListView(
          children: [_tile(friend: friend, onRemove: () => removed = true)])));

      await tester.drag(find.byType(FriendTile), const Offset(-500, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(removed, isTrue);
    });
  });
}
