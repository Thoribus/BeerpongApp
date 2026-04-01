import 'package:beerpongapp/l10n/app_localizations.dart';
import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/friends/friends_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

User _user(
  String id, {
  double totalScore = 0,
  int wins = 0,
  int losses = 0,
  int totalThrows = 0,
  int onFire = 0,
  int bounceAttempts = 0,
  int bounceMakes = 0,
  DateTime? lastGameAt,
}) {
  return User(
    id: id,
    username: id,
    totalScore: totalScore,
    wins: wins,
    losses: losses,
    totalThrows: totalThrows,
    onFire: onFire,
    bounceAttempts: bounceAttempts,
    bounceMakes: bounceMakes,
    lastGameAt: lastGameAt,
  );
}

GameStatistics _sharedGame(
  String id, {
  required DateTime date,
  required String currentUserId,
  required String friendId,
  required bool currentUserWon,
  int myScore = 10,
  int myThrows = 20,
  int oppScore = 6,
}) {
  return GameStatistics(
    id: id,
    date: date,
    winningTeam: currentUserWon ? 'Team 1' : 'Team 2',
    team1Players: [
      Player(
        name: currentUserId,
        score: myScore.toDouble(),
        throws: myThrows,
        user: User(id: currentUserId, username: currentUserId),
      ),
    ],
    team2Players: [
      Player(
        name: friendId,
        score: oppScore.toDouble(),
        throws: 20,
        user: User(id: friendId, username: friendId),
      ),
    ],
    participants: [currentUserId, friendId],
  );
}

Widget _buildScreen({
  required User currentUser,
  required List<User> friends,
  required List<GameStatistics> games,
  required int Function() incrementFriendLoads,
  required int Function() incrementGameLoads,
}) {
  final provider = UserProvider()..setUserForTesting(currentUser);
  return ChangeNotifierProvider<UserProvider>.value(
    value: provider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FriendsListScreen(
        friendsLoader: (_) {
          incrementFriendLoads();
          return Future.value(friends);
        },
        gamesLoader: (_) {
          incrementGameLoads();
          return Future.value(games);
        },
      ),
    ),
  );
}

void main() {
  group('FriendsListScreen Phase 1-3', () {
    testWidgets('loads friends/games once (no per-friend N+1 behavior)',
        (tester) async {
      var friendLoads = 0;
      var gameLoads = 0;
      int incFriend() => ++friendLoads;
      int incGames() => ++gameLoads;

      await tester.pumpWidget(
        _buildScreen(
          currentUser: _user('me'),
          friends: List.generate(5, (i) => _user('f$i')),
          games: const [],
          incrementFriendLoads: incFriend,
          incrementGameLoads: incGames,
        ),
      );
      await tester.pumpAndSettle();

      expect(friendLoads, 1);
      expect(gameLoads, 1);

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Socials'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Friendlist'));
      await tester.pumpAndSettle();

      expect(friendLoads, 1);
      expect(gameLoads, 1);
    });

    testWidgets('leaderboard shows new sort chips and marks current user',
        (tester) async {
      var friendLoads = 0;
      var gameLoads = 0;

      await tester.pumpWidget(
        _buildScreen(
          currentUser: _user('me', totalScore: 1, wins: 0, losses: 3),
          friends: [
            _user('top1',
                totalScore: 100, wins: 40, losses: 2, totalThrows: 100),
            _user('top2', totalScore: 90, wins: 30, losses: 3, totalThrows: 80),
            _user('top3', totalScore: 80, wins: 20, losses: 5, totalThrows: 70),
            _user('rank4',
                totalScore: 70, wins: 10, losses: 10, totalThrows: 60),
          ],
          games: const [],
          incrementFriendLoads: () => ++friendLoads,
          incrementGameLoads: () => ++gameLoads,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();

      expect(find.text('Hit Rate'), findsOneWidget);
      expect(find.text('On Fire'), findsOneWidget);
      expect(find.text('Bounce %'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('me (you)'), findsOneWidget);
    });

    testWidgets(
        'social feed renders shared game, streak, achievement, active cards',
        (tester) async {
      var friendLoads = 0;
      var gameLoads = 0;
      final now = DateTime.now();

      await tester.pumpWidget(
        _buildScreen(
          currentUser: _user('me'),
          friends: [
            _user(
              'f1',
              wins: 60,
              onFire: 55,
              lastGameAt: now.subtract(const Duration(days: 2)),
            ),
          ],
          games: [
            _sharedGame(
              'g1',
              date: now.subtract(const Duration(hours: 1)),
              currentUserId: 'me',
              friendId: 'f1',
              currentUserWon: true,
            ),
            _sharedGame(
              'g2',
              date: now.subtract(const Duration(days: 1)),
              currentUserId: 'me',
              friendId: 'f1',
              currentUserWon: true,
            ),
            _sharedGame(
              'g3',
              date: now.subtract(const Duration(days: 2)),
              currentUserId: 'me',
              friendId: 'f1',
              currentUserWon: true,
            ),
          ],
          incrementFriendLoads: () => ++friendLoads,
          incrementGameLoads: () => ++gameLoads,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Socials'));
      await tester.pumpAndSettle();

      expect(find.text('Beat f1'), findsWidgets);
      expect(find.textContaining('10–6 · 50% hit rate'), findsWidgets);
      expect(find.text('🔥 3-game win streak!'), findsOneWidget);
      expect(find.text('🏆 f1 reached 50 wins'), findsOneWidget);
      expect(find.text('🔥 f1 went on fire 50+ times'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('f1 is active'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('f1 is active'), findsOneWidget);
    });

    testWidgets('friend list uses relative timestamps (hours)', (tester) async {
      var friendLoads = 0;
      var gameLoads = 0;

      await tester.pumpWidget(
        _buildScreen(
          currentUser: _user('me'),
          friends: [
            _user('f1',
                lastGameAt: DateTime.now().subtract(const Duration(hours: 3))),
          ],
          games: const [],
          incrementFriendLoads: () => ++friendLoads,
          incrementGameLoads: () => ++gameLoads,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3h ago'), findsOneWidget);
    });
  });
}
