import 'package:beerpongapp/models/game_statistics.dart';
import 'package:beerpongapp/models/player.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/screens/friends/friends_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

GameStatistics _game({
  required String id,
  required DateTime date,
  required String currentUserId,
  required String friendId,
}) {
  return GameStatistics(
    id: id,
    date: date,
    winningTeam: 'Team 1',
    team1Players: [
      Player(
        name: currentUserId,
        score: 10,
        throws: 20,
        user: User(id: currentUserId, username: currentUserId),
      ),
    ],
    team2Players: [
      Player(
        name: friendId,
        score: 6,
        throws: 20,
        user: User(id: friendId, username: friendId),
      ),
    ],
    participants: [currentUserId, friendId],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('friends screen phase1-3 flow works end-to-end', (tester) async {
    final now = DateTime.now();
    final provider = UserProvider()..setUserForTesting(_user('me'));

    await tester.pumpWidget(
      ChangeNotifierProvider<UserProvider>.value(
        value: provider,
        child: MaterialApp(
          home: FriendsListScreen(
            friendsLoader: (_) async => [
              _user(
                'f1',
                wins: 60,
                onFire: 55,
                totalScore: 80,
                totalThrows: 100,
                bounceAttempts: 10,
                bounceMakes: 6,
                lastGameAt: now.subtract(const Duration(days: 2)),
              ),
              _user(
                'f2',
                totalScore: 100,
                wins: 40,
                losses: 10,
                totalThrows: 120,
              ),
              _user(
                'f3',
                totalScore: 90,
                wins: 30,
                losses: 10,
                totalThrows: 110,
              ),
              _user(
                'f4',
                totalScore: 70,
                wins: 20,
                losses: 20,
                totalThrows: 100,
              ),
            ],
            gamesLoader: (_) async => [
              _game(
                id: 'g1',
                date: now.subtract(const Duration(hours: 1)),
                currentUserId: 'me',
                friendId: 'f1',
              ),
              _game(
                id: 'g2',
                date: now.subtract(const Duration(days: 1)),
                currentUserId: 'me',
                friendId: 'f1',
              ),
              _game(
                id: 'g3',
                date: now.subtract(const Duration(days: 2)),
                currentUserId: 'me',
                friendId: 'f1',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Friendlist'), findsOneWidget);
    expect(find.text('f1'), findsWidgets);

    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    expect(find.text('Hit Rate'), findsOneWidget);
    expect(find.text('On Fire'), findsOneWidget);
    expect(find.text('Bounce %'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);

    await tester.tap(find.text('Socials'));
    await tester.pumpAndSettle();
    expect(find.text('Beat f1'), findsWidgets);
    expect(find.text('🔥 3-game win streak!'), findsOneWidget);
    expect(find.text('Play Again'), findsWidgets);
  });
}
